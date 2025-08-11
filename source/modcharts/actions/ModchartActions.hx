package modcharts.actions;

import haxe.Json;
import openfl.net.FileReference;
#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import psych.script.FunkinLua;
#end

import modcharts.core.Modifier;
import modcharts.systems.PlayfieldSystem;
import modcharts.transform.NoteTransform;
import modcharts.utils.ModchartHelper;
import modcharts.systems.*;

import openfl.events.Event;
import openfl.events.IOErrorEvent;

using StringTools;

//for lua and hscript
class ModchartActions
{
    public static function loadLuaFunctions(funk:FunkinLua)
    {
        #if PSYCH
        #if LUA_ALLOWED
        //for (funkin in Luanb)
        //{
            var lua = funk.lua;
            Lua_helper.add_callback(lua, 'startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1){
                startMod(name,modClass,type,pf);

                PlayState.instance.playfieldRenderer.modifierTable.reconstructTable(); //needs to be reconstructed for lua modcharts
            });
            Lua_helper.add_callback(lua, 'setMod', function(name:String, value:Float){
                setMod(name, value);
            });
            Lua_helper.add_callback(lua, 'setSubMod', function(name:String, subValName:String, value:Float){
                setSubMod(name, subValName,value);
            });
            Lua_helper.add_callback(lua, 'setModTargetLane', function(name:String, value:Int){
                setModTargetLane(name, value);
            });
            Lua_helper.add_callback(lua, 'setModPlayfield', function(name:String, value:Int){
                setModPlayfield(name,value);
            });
            Lua_helper.add_callback(lua, 'ease', function(beat:Float, length:Float, modName:String, easeName:String, value:Float = 0, endValue:Float = 1, ?type:String = '', ?pf:Int = -1, ?lane:Int = -1){
                ease(beat, length, easeName, [modName, value, endValue, type, pf, lane], PlayState.instance);
            });
            Lua_helper.add_callback(lua, 'set', function(beat:Float, modName:String, value:Float = 0, ?type:String = '', ?pf:Int = -1, ?lane:Int = -1){
                set(beat, [modName, value, type, pf, lane], PlayState.instance);
            });
        #end
        #end
    }

    public static function startMod(name:String, modClass:String, type:String = '', pf:Int = -1, ?instance:Dynamic)
    {
        if (instance == null)
            instance = PlayState.instance;

        var renderer = instance.playfieldRenderer;
        if (renderer == null)
            return;

        renderer.modifierTable.add(new Modifier(name, getTypeFromString(type), pf));
        if (modClass != '' && modClass != null)
        {
            var mod = renderer.modifierTable.modifiers.get(name);
            if (mod != null)
            {
                mod.currentValue = mod.baseValue;
                for (subVal in mod.subValues.keys())
                {
                    mod.subValues.get(subVal).value = mod.subValues.get(subVal).baseValue;
                }
                if (renderer.modchart != null && renderer.modchart.customModifiers.exists(modClass))
                {
                    mod.modClass = modClass;
                    renderer.modchart.customModifiers.get(modClass).call('create', [name]);
                }
            }
        }
    }

    public static function setMod(name:String, value:Float, ?subValName:String = '', ?instance:Dynamic)
    {
        if (instance == null)
            instance = PlayState.instance;

        var renderer = instance.playfieldRenderer;
        if (renderer == null)
            return;

        var mod = renderer.modifierTable.modifiers.get(name);
        if (mod != null)
        {
            if (subValName != '')
            {
                if (mod.subValues.exists(subValName))
                {
                    mod.subValues.get(subValName).value = value;
                    if (mod.modClass != '' && renderer.modchart != null && renderer.modchart.customModifiers.exists(mod.modClass))
                        renderer.modchart.customModifiers.get(mod.modClass).call('setSubValue', [name, subValName, value]);
                }
            }
            else
            {
                mod.currentValue = value;
                if (mod.modClass != '' && renderer.modchart != null && renderer.modchart.customModifiers.exists(mod.modClass))
                    renderer.modchart.customModifiers.get(mod.modClass).call('set', [name, value]);
            }
        }
    }

    public static function setSubMod(name:String, subValName:String, value:Float, ?instance:Dynamic)
    {
        setMod(name, value, subValName, instance);
    }

    public static function setModTargetLane(name:String, lane:Int, ?instance:Dynamic)
    {
        if (instance == null)
            instance = PlayState.instance;

        var renderer = instance.playfieldRenderer;
        if (renderer == null)
            return;

        var mod = renderer.modifierTable.modifiers.get(name);
        if (mod != null)
        {
            mod.targetLane = lane;
            if (mod.modClass != '' && renderer.modchart != null && renderer.modchart.customModifiers.exists(mod.modClass))
                renderer.modchart.customModifiers.get(mod.modClass).call('setTargetLane', [name, lane]);
        }
    }

    public static function setModPlayfield(name:String, pf:Int, ?instance:Dynamic)
    {
        if (instance == null)
            instance = PlayState.instance;

        var renderer = instance.playfieldRenderer;
        if (renderer == null)
            return;

        var mod = renderer.modifierTable.modifiers.get(name);
        if (mod != null)
        {
            mod.playfield = pf;
            if (mod.modClass != '' && renderer.modchart != null && renderer.modchart.customModifiers.exists(mod.modClass))
                renderer.modchart.customModifiers.get(mod.modClass).call('setPlayfield', [name, pf]);
        }
    }

    public static function ease(beat:Float, length:Float, easeName:String, data:Array<Dynamic>, ?instance:Dynamic)
    {
        if (instance == null)
            instance = PlayState.instance;

        var renderer = instance.playfieldRenderer;
        if (renderer == null)
            return;

        var time = ModchartHelper.getTimeFromBeat(beat);
        var endTime = ModchartHelper.getTimeFromBeat(beat + length);

        var modName = Std.string(data[0]);
        var startValue = data[1];
        var endValue = data[2];
        var type = data[3];
        var pf = data[4];
        var lane = data[5];

        var ease = ModchartHelper.getEaseFromString(easeName);
        var mod = renderer.modifierTable.modifiers.get(modName);
        if (mod != null)
        {
            var subValName = '';
            if (mod.subValues.exists(modName))
                subValName = modName;

            renderer.eventManager.addEvent(beat, function(args:Array<String>){
                var mod = renderer.modifierTable.modifiers.get(modName);
                if (mod != null)
                {
                    var currentTime = Conductor.songPosition;
                    var endTime = ModchartHelper.getTimeFromBeat(beat + length);
                    var timeDiff = endTime - currentTime;
                    var totalTime = ModchartHelper.getTimeFromBeat(beat + length) - ModchartHelper.getTimeFromBeat(beat);
                    var percent = 1 - (timeDiff / totalTime);
                    var value = FlxMath.lerp(startValue, endValue, ease(percent));

                    if (subValName != '')
                        setSubMod(modName, subValName, value, instance);
                    else
                        setMod(modName, value, '', instance);
                }
            }, []);
        }
    }

    public static function set(beat:Float, data:Array<Dynamic>, ?instance:Dynamic)
    {
        if (instance == null)
            instance = PlayState.instance;

        var renderer = instance.playfieldRenderer;
        if (renderer == null)
            return;

        var modName = Std.string(data[0]);
        var value = data[1];
        var type = data[2];
        var pf = data[3];
        var lane = data[4];

        renderer.eventManager.addEvent(beat, function(args:Array<String>){
            setMod(modName, value, '', instance);
        }, []);
    }

    private static function getTypeFromString(string:String):ModifierType
    {
        switch(string.toLowerCase())
        {
            case 'playeronly': return PLAYERONLY;
            case 'opponentonly': return OPPONENTONLY;
            case 'lanespecific': return LANESPECIFIC;
            default: return ALL;
        }
    }
}