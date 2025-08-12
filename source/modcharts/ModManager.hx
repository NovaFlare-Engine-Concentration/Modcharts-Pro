package modcharts;

import modcharts.engine.PlayfieldRenderer;
import modcharts.engine.ModTable;
import modcharts.engine.ModchartEventManager;
import modcharts.modifiers.Modifier;
import modcharts.modifiers.Modifier.ModifierType;
import modcharts.modifiers.Modifier.EaseCurveModifier;
import modcharts.math.Playfield;
import modcharts.math.NotePositionData;
import modcharts.integration.ModchartUtil;
import modcharts.integration.NoteMovement;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import states.PlayState;
import objects.Note;
import objects.StrumNote;
import backend.Conductor;

using StringTools;

class ModManager extends FlxSprite
{
    // 核心组件
    public var renderer:PlayfieldRenderer;
    public var modTable(get, null):ModTable;
    public var eventManager(get, null):ModchartEventManager;
    
    // 便捷访问属性
    private function get_modTable():ModTable return renderer.modifierTable;
    private function get_eventManager():ModchartEventManager return renderer.eventManager;
    
    /**
     * 创建一个新的 ModManager 实例
     * @param strumGroup StrumNote 组
     * @param notes Note 组
     * @param instance PlayState 实例
     */
    public function new(strumGroup:FlxTypedGroup<StrumNote>, notes:FlxTypedGroup<Note>, camera:FlxCamera, instance:PlayState) 
    {
        super(0, 0);
        renderer = new PlayfieldRenderer(strumGroup, notes, instance);
        renderer.cameras = [camera];
        instance.add(renderer);
        visible = false; // ModManager 本身不绘制，由 renderer 绘制
    }
    
    // ==================== 修饰符管理方法 ====================
    
    /**
     * 添加一个新的修饰符
     * @param name 修饰符名称
     * @param modClass 修饰符类名
     * @param type 修饰符类型 (ALL, PLAYERONLY, OPPONENTONLY, LANESPECIFIC)
     * @param playfield 播放场索引 (-1 表示所有播放场)
     */
    public function addModifier(name:String, modClass:String, type:String = "ALL", playfield:Int = -1):Void
    {
        startMod(name, modClass, type, playfield);
        modTable.reconstructTable();
    }
    
    /**
     * 设置修饰符的值
     * @param name 修饰符名称
     * @param value 值
     */
    public function setModifier(name:String, value:Float):Void
    {
        setMod(name, value);
    }
    
    /**
     * 设置子修饰符的值
     * @param name 修饰符名称
     * @param subValueName 子修饰符名称
     * @param value 值
     */
    public function setSubModifier(name:String, subValueName:String, value:Float):Void
    {
        setSubMod(name, subValueName, value);
    }
    
    /**
     * 设置修饰符的目标轨道
     * @param name 修饰符名称
     * @param lane 轨道索引
     */
    public function setModifierTargetLane(name:String, lane:Int):Void
    {
        setModTargetLane(name, lane);
    }
    
    /**
     * 设置修饰符的播放场
     * @param name 修饰符名称
     * @param playfield 播放场索引
     */
    public function setModifierPlayfield(name:String, playfield:Int):Void
    {
        setModPlayfield(name, playfield);
    }
    
    /**
     * 获取修饰符的当前值
     * @param name 修饰符名称
     * @return 修饰符当前值
     */
    public function getModifierValue(name:String):Float
    {
        if (modTable.modifiers.exists(name))
            return modTable.modifiers.get(name).currentValue;
        return 0;
    }
    
    /**
     * 获取子修饰符的当前值
     * @param name 修饰符名称
     * @param subValueName 子修饰符名称
     * @return 子修饰符当前值
     */
    public function getSubModifierValue(name:String, subValueName:String):Float
    {
        if (modTable.modifiers.exists(name) && modTable.modifiers.get(name).subValues.exists(subValueName))
            return modTable.modifiers.get(name).subValues.get(subValueName).value;
        return 0;
    }
    
    /**
     * 为修饰符添加动画过渡
     * @param modifier 修饰符名称
     * @param value 目标值
     * @param time 过渡时间(秒)
     * @param ease 缓动函数名称
     */
    public function tweenModifier(modifier:String, value:Float, time:Float, ease:String = "linear"):Void
    {
        tweenMod(modifier, value, time, ease);
    }
    
    /**
     * 为子修饰符添加动画过渡
     * @param modifier 修饰符名称
     * @param subValue 子修饰符名称
     * @param value 目标值
     * @param time 过渡时间(秒)
     * @param ease 缓动函数名称
     */
    public function tweenSubModifier(modifier:String, subValue:String, value:Float, time:Float, ease:String = "linear"):Void
    {
        tweenModSubValue(modifier, subValue, value, time, ease);
    }
    
    /**
     * 设置修饰符的缓动函数
     * @param name 修饰符名称
     * @param ease 缓动函数名称
     */
    public function setModifierEaseFunc(name:String, ease:String):Void
    {
        setModEaseFunc(name, ease);
    }
    
    /**
     * 移除修饰符
     * @param name 修饰符名称
     */
    public function removeModifier(name:String):Void
    {
        modTable.remove(name);
        modTable.reconstructTable();
    }
    
    /**
     * 清除所有修饰符
     */
    public function clearModifiers():Void
    {
        modTable.clear();
        modTable.reconstructTable();
    }
    
    /**
     * 重置所有修饰符到基础值
     */
    public function resetModifiers():Void
    {
        modTable.resetMods();
    }
    
    // ==================== 播放场管理方法 ====================
    
    /**
     * 添加新的播放场
     * @param x X 坐标偏移
     * @param y Y 坐标偏移
     * @param z Z 坐标偏移
     * @param alpha 透明度
     */
    public function addPlayfield(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?alpha:Float = 1):Void
    {
        addPlayfieldInternal(x, y, z, alpha);
    }
    
    /**
     * 移除指定索引的播放场
     * @param index 播放场索引
     */
    public function removePlayfield(index:Int):Void
    {
        removePlayfieldInternal(index);
    }
    
    /**
     * 获取播放场数量
     * @return 播放场数量
     */
    public function getPlayfieldCount():Int
    {
        return renderer.playfields.length;
    }
    
    /**
     * 设置播放场属性
     * @param index 播放场索引
     * @param x X 坐标偏移
     * @param y Y 坐标偏移
     * @param z Z 坐标偏移
     * @param alpha 透明度
     */
    public function setPlayfield(index:Int, ?x:Float, ?y:Float, ?z:Float, ?alpha:Float):Void
    {
        if (index >= 0 && index < renderer.playfields.length)
        {
            var pf:Playfield = renderer.playfields[index];
            if (x != null) pf.x = x;
            if (y != null) pf.y = y;
            if (z != null) pf.z = z;
            if (alpha != null) pf.alpha = alpha;
        }
    }
    
    // ==================== 事件管理方法 ====================
    
    /**
     * 添加设置事件
     * @param beat 触发节拍
     * @param args 参数字符串 (格式: "value,modifier,value,modifier,...")
     */
    public function addSetEvent(beat:Float, args:String):Void
    {
        setEvent(beat, args);
    }
    
    /**
     * 添加缓动事件
     * @param beat 触发节拍
     * @param time 缓动时间(秒)
     * @param ease 缓动函数名称
     * @param args 参数字符串 (格式: "value,modifier,value,modifier,...")
     */
    public function addEaseEvent(beat:Float, time:Float, ease:String, args:String):Void
    {
        easeEvent(beat, time, ease, args);
    }
    
    /**
     * 清除所有事件
     */
    public function clearEvents():Void
    {
        eventManager.clearEvents();
    }
    
    // ==================== 实用方法 ====================
    
    /**
     * 获取 PlayState 实例
     * @return PlayState 实例
     */
    private function getPlayState():PlayState
    {
        return renderer.playStateInstance;
    }
    
    /**
     * 更新管理器
     * @param elapsed 经过的时间
     */
    override public function update(elapsed:Float):Void
    {
        renderer.update(elapsed);
    }
    
    /**
     * 绘制管理器
     */
    override public function draw():Void
    {
        renderer.draw();
    }
    
    /**
     * 设置编辑器模式
     * @param inEditor 是否在编辑器中
     */
    public function setEditorMode(inEditor:Bool):Void
    {
        renderer.inEditor = inEditor;
    }
    
    /**
     * 设置播放速度
     * @param speed 播放速度
     */
    public function setSpeed(speed:Float):Void
    {
        renderer.speed = speed;
    }
    
    // ==================== 直接迁移的 ModchartFuncs 功能 ====================
    
    public function startMod(name:String, modClass:String, type:String = "", pf:Int = -1)
    {

        var mod = Type.resolveClass('modcharts.modifiers.' + modClass);
        if (mod == null) {mod = Type.resolveClass('modcharts.modifiers.' + modClass + "Modifier");} //dont need to add "Modifier" to the end of every mod
        
        if (mod != null)
        {
            var modType = getModTypeFromString(type);
            var modifier = Type.createInstance(mod, [name, modType, pf]);
            renderer.modifierTable.add(modifier);
        }
    }
    
    public function getModTypeFromString(type:String)
    {
        var modType = ModifierType.ALL;
        switch (type.toLowerCase())
        {
            case 'player':
                modType = ModifierType.PLAYERONLY;
            case 'opponent':
                modType = ModifierType.OPPONENTONLY;
            case 'lane' | 'lanespecific':
                modType = ModifierType.LANESPECIFIC;
        }
        return modType;
    }
    
    public function setMod(name:String, value:Float)
    {

        if (renderer.modifierTable.modifiers.exists(name))
            renderer.modifierTable.modifiers.get(name).currentValue = value;
    }
    
    public function setSubMod(name:String, subValName:String, value:Float)
    {

        if (renderer.modifierTable.modifiers.exists(name))
            renderer.modifierTable.modifiers.get(name).subValues.get(subValName).value = value;
    }
    
    public function setModTargetLane(name:String, value:Int)
    {

        if (renderer.modifierTable.modifiers.exists(name))
            renderer.modifierTable.modifiers.get(name).targetLane = value;
    }
    
    public function setModPlayfield(name:String, value:Int)
    {

        if (renderer.modifierTable.modifiers.exists(name))
            renderer.modifierTable.modifiers.get(name).playfield = value;
    }
    
    public function addPlayfieldInternal(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?alpha:Float = 1)
    {

        renderer.addNewPlayfield(x, y, z, alpha);
    }
    
    public function removePlayfieldInternal(idx:Int)
    {

        renderer.playfields.remove(renderer.playfields[idx]);
    }
    
    public function tweenMod(modifier:String, val:Float, time:Float, ease:String)
    {

        renderer.modifierTable.tweenModifier(modifier, val, time, ease, Modifier.beat);
    }
    
    public function tweenModSubValue(modifier:String, subValue:String, val:Float, time:Float, ease:String)
    {

        renderer.modifierTable.tweenModifierSubValue(modifier, subValue, val, time, ease, Modifier.beat);
    }
    
    public function setModEaseFunc(name:String, ease:String)
    {

        if (renderer.modifierTable.modifiers.exists(name))
        {
            var mod = renderer.modifierTable.modifiers.get(name);
            if (Std.isOfType(mod, EaseCurveModifier))
            {
                var temp:Dynamic = mod;
                var castedMod:EaseCurveModifier = temp;
                castedMod.setEase(ease);
            }
        }
    }
    
    public function setEvent(beat:Float, argsAsString:String)
    {

        var args = argsAsString.trim().replace(' ', '').split(',');
        
        renderer.eventManager.addEvent(beat, function(arguments:Array<String>) {
            for (i in 0...Math.floor(arguments.length/2))
            {
                var name:String = Std.string(arguments[1 + (i*2)]);
                var value:Float = Std.parseFloat(arguments[0 + (i*2)]);
                if(Math.isNaN(value))
                    value = 0;
                if (renderer.modifierTable.modifiers.exists(name))
                {
                    renderer.modifierTable.modifiers.get(name).currentValue = value;
                }
                else 
                {
                    var subModCheck = name.split(':');
                    if (subModCheck.length > 1)
                    {
                        var modName = subModCheck[0];
                        var subModName = subModCheck[1];
                        if (renderer.modifierTable.modifiers.exists(modName))
                            renderer.modifierTable.modifiers.get(modName).subValues.get(subModName).value = value;
                    }
                }
            }
        }, args);
    }
    
    public function easeEvent(beat:Float, time:Float, ease:String, argsAsString:String) : Void
    {

        
        if(Math.isNaN(time))
            time = 1;
        
        var args = argsAsString.trim().replace(' ', '').split(',');
        
        var func = function(arguments:Array<String>) {
            
            for (i in 0...Math.floor(arguments.length/2))
            {
                var name:String = Std.string(arguments[1 + (i*2)]);
                var value:Float = Std.parseFloat(arguments[0 + (i*2)]);
                if(Math.isNaN(value))
                    value = 0;
                var subModCheck = name.split(':');
                if (subModCheck.length > 1)
                {
                    var modName = subModCheck[0];
                    var subModName = subModCheck[1];
                    //trace(subModCheck);
                    renderer.modifierTable.tweenModifierSubValue(modName,subModName,value,time*Conductor.crochet*0.001,ease, beat);
                }
                else
                    renderer.modifierTable.tweenModifier(name,value,time*Conductor.crochet*0.001,ease, beat);
            }
        };
        renderer.eventManager.addEvent(beat, func, args);
    }
}
