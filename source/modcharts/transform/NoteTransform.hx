package modcharts.transform;

import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxG;

import states.PlayState;
import objects.Note;

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

    public static function getDefaultStrumPos(game:PlayState)
    {
        defaultStrumX = []; //reset
        defaultStrumY = [];
        defaultScale = [];
        arrowSizes = [];
        keyCount = game.strumLineNotes.length-game.playerStrums.length; //base game doesnt have opponent strums as group
        playerKeyCount = game.playerStrums.length;

        for (i in #if (LEATHER || KADE) 0...PlayState.strumLineNotes.members.length #else 0...game.strumLineNotes.members.length #end)
        {
            var strum = game.strumLineNotes.members[i];
            defaultStrumX.push(strum.x);
            defaultStrumY.push(strum.y);
            var s = 0.7;
            defaultScale.push(s);
            arrowSizes.push(strum.width);
        }
    }

    public static function getScrollSpeed(game:PlayState)
    {
        return PlayState.songSpeed;
    }

    public static function getPixelStrumPos(lane:Int, downscroll:Bool, instance:ModchartMusicBeatState)
    {
        var playerStrums = PlayState.instance.playerStrums;
        var strumLineNotes = PlayState.strumLineNotes;

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

