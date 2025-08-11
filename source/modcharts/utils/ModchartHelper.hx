package modcharts.utils;

import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import openfl.geom.Vector3D;
import flixel.FlxG;

import states.game.PlayState;
import obj.Note;

using StringTools;

class ModchartHelper
{
    public static function getDownscroll(instance:ModchartMusicBeatState)
    {
        //need to test each engine
        //not expecting all to work
        #if PSYCH
        return ClientPrefs.downScroll;
        #elseif LEATHER
        return utilities.Options.getData("downscroll");
        #elseif ANDROMEDA //dunno why youd use this on andromeda but whatever, already got its own cool modchart system
        return instance.currentOptions.downScroll;
        #elseif KADE
        return PlayStateChangeables.useDownscroll;
        #elseif FOREVER_LEGACY //forever might not work just yet because of the multiple strumgroups
        return Init.trueSettings.get('Downscroll');
        #elseif FPSPLUS
        return Config.downscroll;
        #elseif MIC_D_UP //basically no one uses this anymore
        return MainVariables._variables.scroll == "down"
        #else
        return false;
        #end
    }

    public static function getMiddlescroll(instance:ModchartMusicBeatState)
    {
        #if PSYCH
        return ClientPrefs.middleScroll;
        #elseif LEATHER
        return utilities.Options.getData("middlescroll");
        #else
        return false;
        #end
    }

    public static function getScrollSpeed(game:PlayState)
    {
        #if PSYCH
        return PlayState.songSpeed;
        #elseif LEATHER
        return utilities.Options.getData("scrollspeed");
        #elseif ANDROMEDA
        return game.currentOptions.scrollSpeed;
        #elseif KADE
        return PlayStateChangeables.scrollSpeed;
        #elseif FOREVER_LEGACY
        return Init.trueSettings.get('Scroll Speed');
        #elseif FPSPLUS
        return Config.scrollSpeed;
        #elseif MIC_D_UP
        return MainVariables._variables.scrollSpeed == "1.0";
        #else
        return 1.0;
        #end
    }

    public static function getTimeFromBeat(beat:Float):Float
    {
        #if LEATHER
        var crochet = ((60 / game.Conductor.bpm) * 1000);
        return (beat * crochet);
        #else
        var crochet = ((60 / PlayState.instance.bpm) * 1000);
        return (beat * crochet);
        #end
    }

    public static function getBeatFromTime(time:Float):Float
    {
        #if LEATHER
        var crochet = ((60 / game.Conductor.bpm) * 1000);
        return (time / crochet);
        #else
        var crochet = ((60 / PlayState.instance.bpm) * 1000);
        return (time / crochet);
        #end
    }

    public static function lerp(a:Float, b:Float, ratio:Float):Float
    {
        return a + (b - a) * ratio;
    }

    public static function coolLerp(a:Float, b:Float, ratio:Float):Float //from andromeda
    {
        return FlxMath.lerp(a, b, FlxMath.fastSin(ratio * FlxAngle.TO_RAD * 90));
    }

    public static function clamp(value:Float, min:Float, max:Float):Float
    {
        return FlxMath.bound(value, min, max);
    }

    public static function getEaseFromString(ease:String):Float->Float
    {
        switch(ease.toLowerCase())
        {
            case "linear": return FlxEase.linear;
            case "cubein": return FlxEase.cubeIn;
            case "cubeinout": return FlxEase.cubeInOut;
            case "cubeout": return FlxEase.cubeOut;
            case "quadin": return FlxEase.quadIn;
            case "quadinout": return FlxEase.quadInOut;
            case "quadout": return FlxEase.quadOut;
            case "bouncein": return FlxEase.bounceIn;
            case "bounceinout": return FlxEase.bounceInOut;
            case "bounceout": return FlxEase.bounceOut;
            case "circin": return FlxEase.circIn;
            case "circinout": return FlxEase.circInOut;
            case "circout": return FlxEase.circOut;
            case "backin": return FlxEase.backIn;
            case "backinout": return FlxEase.backInOut;
            case "backout": return FlxEase.backOut;
            case "elasticin": return FlxEase.elasticIn;
            case "elasticinout": return FlxEase.elasticInOut;
            case "elasticout": return FlxEase.elasticOut;
            case "sinein": return FlxEase.sineIn;
            case "sineinout": return FlxEase.sineInOut;
            case "sineout": return FlxEase.sineOut;
            case "smoothstepin": return FlxEase.smoothStepIn;
            case "smoothstepinout": return FlxEase.smoothStepInOut;
            case "smoothstepout": return FlxEase.smoothStepOut;
            case "smootherstepin": return FlxEase.smootherStepIn;
            case "smootherstepinout": return FlxEase.smootherStepInOut;
            case "smootherstepout": return FlxEase.smootherStepOut;
            default: return FlxEase.linear;
        }
    }
}