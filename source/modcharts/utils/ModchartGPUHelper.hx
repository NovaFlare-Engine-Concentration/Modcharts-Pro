package modcharts.utils;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.RectangleTexture;

import modcharts.render.GPURenderSystem;

class ModchartGPUHelper
{
    /**
     * 缓存位图到GPU，同时保留原始位图数据以便modchart使用
     * @param key 位图的键
     * @param bitmapData 位图数据
     * @param gpuRenderer GPU渲染系统实例
     * @return 是否成功缓存
     */
    public static function cacheBitmapForModchart(key:String, bitmapData:BitmapData, gpuRenderer:GPURenderSystem):Bool
    {
        if (gpuRenderer == null || !gpuRenderer.enabled)
            return false;

        try {
            // 保存原始位图数据，以便modchart可以访问
            gpuRenderer.modchartTextures.set(key, bitmapData.clone());

            // 创建GPU纹理
            var texture:RectangleTexture = gpuRenderer.context.createRectangleTexture(
                bitmapData.width, 
                bitmapData.height, 
                Context3DTextureFormat.BGRA, 
                true
            );

            texture.uploadFromBitmapData(bitmapData);
            gpuRenderer.textureCache.set(key, texture);

            return true;
        }
        catch (e:Dynamic) {
            trace("缓存位图到GPU失败: " + e);
            return false;
        }
    }

    /**
     * 从GPU缓存获取位图数据
     * @param key 位图的键
     * @param gpuRenderer GPU渲染系统实例
     * @return 位图数据，如果不存在则返回null
     */
    public static function getBitmapFromCache(key:String, gpuRenderer:GPURenderSystem):BitmapData
    {
        if (gpuRenderer == null)
            return null;

        return gpuRenderer.getModchartTexture(key);
    }

    /**
     * 检查GPU是否支持
     * @return 是否支持GPU渲染
     */
    public static function isGPUSupported():Bool
    {
        return GPURenderSystem.isGPUSupported();
    }

    /**
     * 启用或禁用GPU缓存
     * @param enabled 是否启用
     * @param gpuRenderer GPU渲染系统实例
     */
    public static function setGPUCacheEnabled(enabled:Bool, gpuRenderer:GPURenderSystem):Void
    {
        if (gpuRenderer != null)
        {
            gpuRenderer.setGPUCacheEnabled(enabled);
        }
    }

    /**
     * 安全地上传图形到GPU，同时保留原始数据
     * @param graphic 要上传的图形对象
     * @param gpuRenderer GPU渲染系统实例
     * @return 是否成功上传
     */
    public static function safeUploadGraphicToGPU(graphic:FlxGraphic, gpuRenderer:GPURenderSystem):Bool
    {
        if (gpuRenderer == null || !gpuRenderer.enabled || graphic == null)
            return false;

        return gpuRenderer.uploadGraphicToGPU(graphic);
    }

    /**
     * 缓存图形对象，但不立即上传到GPU
     * @param file 文件路径
     * @param bitmap 位图数据
     * @param gpuRenderer GPU渲染系统实例
     * @return 缓存的图形对象
     */
    public static function cacheGraphicWithoutGPUUpload(file:String, bitmap:BitmapData, gpuRenderer:GPURenderSystem):FlxGraphic
    {
        if (gpuRenderer == null)
            return null;

        return gpuRenderer.cacheBitmapForModchart(file, bitmap);
    }
}
