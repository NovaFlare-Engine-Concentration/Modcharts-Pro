package modcharts.transform;

import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxG;

import states.game.PlayState;
import obj.Note;

using StringTools;

class NoteTransform
{
    public static var keyCount = 4;
    public static var playerKeyCount = 4;
    public static var totalKeyCount = 8;
    public static var arrowScale:Float = 0.7;
    public static var arrowSize:Float = 112;
    public static var defaultStrumX:Array<Float> = [];
    public static var defaultStrumY:Array<Float> = [];
    public static var defaultScale:Array<Float> = [];
    public static var arrowSizes:Array<Float> = [];
    #if LEATHER
    public static var leatherEngineOffsetStuff:Map<String, Float> = [];
    #end

    public static function getDefaultStrumPos(game:PlayState)
    {
        defaultStrumX = []; //reset
        defaultStrumY = [];
        defaultScale = [];
        arrowSizes = [];
        keyCount = #if (LEATHER || KADE) PlayState.strumLineNotes.length-PlayState.playerStrums.length #else game.strumLineNotes.length-game.playerStrums.length #end; //base game doesnt have opponent strums as group
        playerKeyCount = #if (LEATHER || KADE) PlayState.playerStrums.length #else game.playerStrums.length #end;

        for (i in #if (LEATHER || KADE) 0...PlayState.strumLineNotes.members.length #else 0...game.strumLineNotes.members.length #end)
        {
            #if (LEATHER || KADE)
            var strum = PlayState.strumLineNotes.members[i];
            #else
            var strum = game.strumLineNotes.members[i];
            #end
            defaultStrumX.push(strum.x);
            defaultStrumY.push(strum.y);
            #if LEATHER
            var localKeyCount = (i < keyCount ? keyCount : playerKeyCount);
            var s = Std.parseFloat(game.ui_settings[0]) * (Std.parseFloat(game.ui_settings[2]) - (Std.parseFloat(game.mania_size[localKeyCount-1])));
            #else
            var s = 0.7;
            #end
            defaultScale.push(s);
            arrowSizes.push(strum.width);
        }
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

    public static function getPixelStrumPos(lane:Int, downscroll:Bool, instance:ModchartMusicBeatState)
    {
        #if PSYCH
        var playerStrums = PlayState.instance.playerStrums;
        var strumLineNotes = PlayState.strumLineNotes;
        #elseif LEATHER
        var playerStrums = PlayState.playerStrums;
        var strumLineNotes = PlayState.strumLineNotes;
        #else
        var playerStrums = instance.playStateInstance.playerStrums;
        var strumLineNotes = instance.playStateInstance.strumLineNotes;
        #end

        var strum = strumLineNotes.members[lane];
        var playerStrum = playerStrums.members[lane % playerKeyCount];
        var x = strum.x;
        var y = strum.y;

        if (downscroll)
        {
            var tempY = strum.y + (strumLineNotes.y - playerStrums.y);
            y = tempY;
        }

        return {x: x, y: y};
    }
}