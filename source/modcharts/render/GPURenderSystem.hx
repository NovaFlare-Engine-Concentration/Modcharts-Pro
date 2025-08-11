package modcharts.render;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display.Shader;
import openfl.display.ShaderParameter;
import openfl.display.ShaderInput;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.RectangleTexture;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.utils.ByteArray;
import openfl.utils.Float32Array;
import openfl.utils.Int32Array;

import modcharts.data.NoteTransformData;
import modcharts.systems.Playfield;
import modcharts.utils.ModchartHelper;
import flixel.graphics.FlxGraphic;

class GPURenderSystem
{
    public var enabled:Bool = true;
    public var shaders:Array<FlxGraphicsShader> = [];
    public var shaderData:Array<Shader> = [];
    public var textureCache:Map<String, Texture> = new Map<String, Texture>();
    public var transformBuffer:Float32Array;
    public var maxNotes:Int = 1024;
    public var context:Context3D;
    public var gpuCacheEnabled:Bool = true;
    public var modchartTextures:Map<String, BitmapData> = new Map<String, BitmapData>();
    public var modchartGraphics:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

    public function new()
    {
        if (FlxG.stage != null && FlxG.stage.stage3Ds != null && FlxG.stage.stage3Ds.length > 0)
        {
            context = FlxG.stage.stage3Ds[0].context3D;
            if (context == null)
            {
                FlxG.stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
                enabled = false;
            }
            else
            {
                init();
            }
        }
        else
        {
            enabled = false;
        }
    }

    private function onContextCreated(e:Event):Void
    {
        context = FlxG.stage.stage3Ds[0].context3D;
        if (context != null)
        {
            enabled = true;
            init();
        }
    }

    private function init():Void
    {
        // 创建变换缓冲区
        transformBuffer = new Float32Array(maxNotes * 16); // 4x4矩阵

        // 初始化着色器
        initShaders();
    }

    private function initShaders():Void
    {
        // 顶点着色器
        var vertexShaderSource = "
            attribute vec3 position;
            attribute vec2 texCoord;
            attribute vec4 color;

            uniform mat4 transformMatrix;
            uniform mat4 projectionMatrix;

            varying vec2 vTexCoord;
            varying vec4 vColor;

            void main(void) {
                gl_Position = projectionMatrix * transformMatrix * vec4(position, 1.0);
                vTexCoord = texCoord;
                vColor = color;
            }
        ";

        // 片段着色器
        var fragmentShaderSource = "
            varying vec2 vTexCoord;
            varying vec4 vColor;

            uniform sampler2D uTexture;
            uniform float alpha;

            void main(void) {
                vec4 texColor = texture2D(uTexture, vTexCoord);
                gl_FragColor = vec4(texColor.rgb * vColor.rgb, texColor.a * vColor.a * alpha);
            }
        ";

        try {
            var shader = new FlxGraphicsShader(vertexShaderSource, fragmentShaderSource);
            shaders.push(shader);
            shaderData.push(shader.glShader);
        }
        catch (e:Dynamic) {
            trace("着色器初始化错误: " + e);
            enabled = false;
        }
    }

    public function updateTransforms(noteData:Array<NoteTransformData>):Void
    {
        if (!enabled || context == null || noteData == null || noteData.length == 0)
            return;

        var count:Int = FlxMath.minInt(noteData.length, maxNotes);

        for (i in 0...count)
        {
            var data = noteData[i];
            var offset = i * 16;

            // 创建4x4变换矩阵
            // 单位矩阵
            transformBuffer[offset] = 1; transformBuffer[offset+1] = 0; transformBuffer[offset+2] = 0; transformBuffer[offset+3] = 0;
            transformBuffer[offset+4] = 0; transformBuffer[offset+5] = 1; transformBuffer[offset+6] = 0; transformBuffer[offset+7] = 0;
            transformBuffer[offset+8] = 0; transformBuffer[offset+9] = 0; transformBuffer[offset+10] = 1; transformBuffer[offset+11] = 0;
            transformBuffer[offset+12] = data.x; transformBuffer[offset+13] = data.y; transformBuffer[offset+14] = data.z; transformBuffer[offset+15] = 1;

            // 应用旋转
            var angleRad = data.angle * Math.PI / 180;
            var cos = Math.cos(angleRad);
            var sin = Math.sin(angleRad);

            // 旋转矩阵绕Z轴
            var rotMatrix = new Matrix3D();
            rotMatrix.appendRotation(data.angle, Vector3D.Z_AXIS);

            // 合并变换
            var transformMatrix = new Matrix3D();
            transformMatrix.appendTranslation(data.x, data.y, data.z);
            transformMatrix.append(rotMatrix);
            transformMatrix.appendScale(data.scaleX, data.scaleY, 1);

            // 将矩阵写入缓冲区
            var rawData = transformMatrix.rawData;
            for (j in 0...16)
            {
                transformBuffer[offset + j] = rawData[j];
            }
        }
    }

    public function uploadTexture(key:String, bitmapData:BitmapData):Texture
    {
        if (!enabled || context == null)
            return null;

        // 检查是否已经缓存了纹理
        if (textureCache.exists(key))
            return textureCache.get(key);

        // 保存原始位图数据，以便在需要时重新创建纹理
        modchartTextures.set(key, bitmapData.clone());

        // 创建纹理
        var texture:RectangleTexture = context.createRectangleTexture(
            bitmapData.width, 
            bitmapData.height, 
            Context3DTextureFormat.BGRA, 
            false
        );

        texture.uploadFromBitmapData(bitmapData);
        textureCache.set(key, texture);

        return texture;
    }

    public function getModchartTexture(key:String):BitmapData
    {
        if (modchartTextures.exists(key))
            return modchartTextures.get(key);
        return null;
    }

    public function cacheBitmapForModchart(file:String, ?bitmap:BitmapData = null):FlxGraphic
    {
        if (bitmap == null)
        {
            #if MODS_ALLOWED
            if (sys.FileSystem.exists(file))
                bitmap = BitmapData.fromFile(file);
            else
            #end
            {
                if (FlxG.assets.exists(file, IMAGE))
                    bitmap = FlxG.assets.getBitmapData(file);
            }
            if (bitmap == null)
                return null;
        }

        // 检查是否已经缓存
        if (modchartGraphics.exists(file))
            return modchartGraphics.get(file);

        // 创建新的图形对象，但不立即上传到GPU
        var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
        newGraphic.persist = true;
        newGraphic.destroyOnNoUse = false;

        // 保存到modchart专用缓存
        modchartGraphics.set(file, newGraphic);

        return newGraphic;
    }

    public function uploadGraphicToGPU(graphic:FlxGraphic):Bool
    {
        if (!enabled || context == null || !gpuCacheEnabled)
            return false;

        try {
            // 如果图形对象已经有纹理，则跳过
            if (graphic.getTexture() != null)
                return true;

            // 创建纹理并上传
            var texture:RectangleTexture = context.createRectangleTexture(
                graphic.bitmap.width, 
                graphic.bitmap.height, 
                Context3DTextureFormat.BGRA, 
                true
            );

            texture.uploadFromBitmapData(graphic.bitmap);

            // 保存原始位图数据引用，以便在需要时重新创建纹理
            modchartTextures.set(graphic.key, graphic.bitmap.clone());

            // 释放原始位图数据以节省内存
            graphic.bitmap.image.data = null;
            graphic.bitmap.dispose();
            graphic.bitmap.disposeImage();

            // 使用GPU纹理创建新的位图
            graphic.bitmap = BitmapData.fromTexture(texture);

            return true;
        }
        catch (e:Dynamic) {
            trace("上传纹理到GPU失败: " + e);
            return false;
        }
    }

    public function render(playfields:Array<Playfield>):Void
    {
        if (!enabled || context == null)
            return;

        // 清除屏幕
        context.clear(0, 0, 0, 0);

        // 设置视口
        context.configureBackBuffer(FlxG.width, FlxG.height, 0, true);

        // 设置投影矩阵
        var projectionMatrix = createProjectionMatrix();

        // 渲染每个playfield
        for (pf in playfields)
        {
            // 设置混合模式
            context.setBlendFactors(
                Context3DBlendFactor.SOURCE_ALPHA, 
                Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
            );

            // 设置着色器
            if (shaders.length > 0)
            {
                var shader = shaders[0];
                var shaderData = shader.glShader;

                // 设置投影矩阵
                if (shaderData.data.projectionMatrix != null)
                {
                    shaderData.data.projectionMatrix.value = projectionMatrix.rawData;
                }

                // 设置全局alpha
                if (shaderData.data.alpha != null)
                {
                    shaderData.data.alpha.value = [pf.alpha];
                }

                // 上传变换矩阵
                if (shaderData.data.transformMatrix != null)
                {
                    shaderData.data.transformMatrix.value = transformBuffer;
                }
            }
        }

        // 显示结果
        context.present();
    }

    private function createProjectionMatrix():Matrix3D
    {
        var projectionMatrix = new Matrix3D();

        // 设置正交投影矩阵
        var left = 0;
        var right = FlxG.width;
        var top = 0;
        var bottom = FlxG.height;
        var near = -1000;
        var far = 1000;

        var rawData = new Vector<Float>(16);

        rawData[0] = 2 / (right - left);
        rawData[5] = 2 / (top - bottom);
        rawData[10] = -2 / (far - near);
        rawData[12] = -(right + left) / (right - left);
        rawData[13] = -(top + bottom) / (top - bottom);
        rawData[14] = -(far + near) / (far - near);
        rawData[15] = 1;

        projectionMatrix.rawData = rawData;

        return projectionMatrix;
    }

    public function clearCache():Void
    {
        // 清除GPU纹理缓存
        for (texture in textureCache)
        {
            if (texture != null)
            {
                texture.dispose();
            }
        }
        textureCache.clear();

        // 清除modchart纹理缓存
        for (bitmap in modchartTextures)
        {
            if (bitmap != null)
            {
                bitmap.dispose();
            }
        }
        modchartTextures.clear();

        // 清除modchart图形缓存
        for (graphic in modchartGraphics)
        {
            if (graphic != null)
            {
                graphic.destroy();
            }
        }
        modchartGraphics.clear();
    }

    public function dispose():Void
    {
        clearCache();
        shaders = [];
        shaderData = [];
        transformBuffer = null;
        enabled = false;
    }

    // 启用或禁用GPU缓存
    public function setGPUCacheEnabled(enabled:Bool):Void
    {
        gpuCacheEnabled = enabled;

        // 如果禁用GPU缓存，则从GPU纹理恢复为CPU位图
        if (!enabled)
        {
            for (key in modchartGraphics.keys())
            {
                var graphic = modchartGraphics.get(key);
                if (graphic != null && modchartTextures.exists(key))
                {
                    var originalBitmap = modchartTextures.get(key);
                    if (originalBitmap != null)
                    {
                        // 恢复原始位图
                        graphic.bitmap = originalBitmap.clone();
                    }
                }
            }
        }
        else
        {
            // 如果启用GPU缓存，则将位图上传到GPU
            for (key in modchartGraphics.keys())
            {
                var graphic = modchartGraphics.get(key);
                if (graphic != null)
                {
                    uploadGraphicToGPU(graphic);
                }
            }
        }
    }

    // 检查GPU是否可用
    public static function isGPUSupported():Bool
    {
        try {
            return FlxG.stage != null && 
                   FlxG.stage.stage3Ds != null && 
                   FlxG.stage.stage3Ds.length > 0 && 
                   FlxG.stage.stage3Ds[0].context3D != null;
        }
        catch (e:Dynamic) {
            return false;
        }
    }
}
