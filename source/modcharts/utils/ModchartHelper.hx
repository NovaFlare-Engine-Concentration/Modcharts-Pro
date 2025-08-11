package modcharts.utils;

import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import openfl.geom.Vector3D;
import flixel.FlxG;

import states.PlayState;
import objects.Note;

using StringTools;

class ModchartHelper
{
    public static function getDownscroll(instance:ModchartMusicBeatState)
    {
        //need to test each engine
        //not expecting all to work
        return ClientPrefs.data.downScroll;
    }

    public static function getMiddlescroll(instance:ModchartMusicBeatState)
    {
        return ClientPrefs.data.middleScroll;
    }

    public static function getScrollSpeed(game:PlayState)
    {
        return PlayState.songSpeed;
    }

    public static function getTimeFromBeat(beat:Float):Float
    {
        var crochet = ((60 / PlayState.instance.bpm) * 1000);
        return (beat * crochet);
    }

    public static function getBeatFromTime(time:Float):Float
    {
        var crochet = ((60 / PlayState.instance.bpm) * 1000);
        return (time / crochet);
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
