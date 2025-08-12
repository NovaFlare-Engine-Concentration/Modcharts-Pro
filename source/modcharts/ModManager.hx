package modcharts;

import modcharts.engine.PlayfieldRenderer;
import modcharts.engine.ModTable;
import modcharts.engine.ModchartEventManager;
import modcharts.modifiers.Modifier;
import modcharts.math.Playfield;
import modcharts.integration.ModchartFuncs;
import modcharts.integration.ModchartUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.PlayState;
import objects.Note;
import objects.StrumNote;

class ModManager
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
        renderer = new PlayfieldRenderer(strumGroup, notes, instance);
        renderer.cameras = [camera];
        add(renderer);
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
        ModchartFuncs.startMod(name, modClass, type, playfield, getPlayState());
        modTable.reconstructTable();
    }
    
    /**
     * 设置修饰符的值
     * @param name 修饰符名称
     * @param value 值
     */
    public function setModifier(name:String, value:Float):Void
    {
        ModchartFuncs.setMod(name, value, getPlayState());
    }
    
    /**
     * 设置子修饰符的值
     * @param name 修饰符名称
     * @param subValueName 子修饰符名称
     * @param value 值
     */
    public function setSubModifier(name:String, subValueName:String, value:Float):Void
    {
        ModchartFuncs.setSubMod(name, subValueName, value, getPlayState());
    }
    
    /**
     * 设置修饰符的目标轨道
     * @param name 修饰符名称
     * @param lane 轨道索引
     */
    public function setModifierTargetLane(name:String, lane:Int):Void
    {
        ModchartFuncs.setModTargetLane(name, lane, getPlayState());
    }
    
    /**
     * 设置修饰符的播放场
     * @param name 修饰符名称
     * @param playfield 播放场索引
     */
    public function setModifierPlayfield(name:String, playfield:Int):Void
    {
        ModchartFuncs.setModPlayfield(name, playfield, getPlayState());
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
        ModchartFuncs.tweenModifier(modifier, value, time, ease, getPlayState());
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
        ModchartFuncs.tweenModifierSubValue(modifier, subValue, value, time, ease, getPlayState());
    }
    
    /**
     * 设置修饰符的缓动函数
     * @param name 修饰符名称
     * @param ease 缓动函数名称
     */
    public function setModifierEaseFunc(name:String, ease:String):Void
    {
        ModchartFuncs.setModEaseFunc(name, ease, getPlayState());
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
        ModchartFuncs.addPlayfield(x, y, z, alpha, getPlayState());
    }
    
    /**
     * 移除指定索引的播放场
     * @param index 播放场索引
     */
    public function removePlayfield(index:Int):Void
    {
        ModchartFuncs.removePlayfield(index, getPlayState());
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
        ModchartFuncs.set(beat, args, getPlayState());
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
        ModchartFuncs.ease(beat, time, ease, args, getPlayState());
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
    public function update(elapsed:Float):Void
    {
        renderer.update(elapsed);
    }
    
    /**
     * 绘制管理器
     */
    public function draw():Void
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
}