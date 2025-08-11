package modcharts.core;

import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.FlxG;

import states.PlayState;
import objects.Note;

enum ModifierType
{
    ALL;
    PLAYERONLY;
    OPPONENTONLY;
    LANESPECIFIC;
}

class ModifierSubValue
{
    public var value:Float = 0.0;
    public var baseValue:Float = 0.0;
    public function new(value:Float)
    {
        this.value = value;
        baseValue = value;
    }
}

class Modifier
{
    public var baseValue:Float = 0;
    public var currentValue:Float = 0;
    public var subValues:Map<String, ModifierSubValue> = new Map<String, ModifierSubValue>();
    public var tag:String = '';
    public var type:ModifierType = ALL;
    public var playfield:Int = -1;
    public var targetLane:Int = -1;
    public var instance:ModchartMusicBeatState = null;
    public var renderer:PlayfieldSystem = null;
    public static var beat:Float = 0;
    public var modClass:String = '';

    public function new(tag:String, ?type:ModifierType = ALL, ?playfield:Int = -1)
    {
        this.tag = tag;
        this.type = type;
        this.playfield = playfield;

        setupSubValues();
    }

    private function setupSubValues()
    {
        //to be overridden
    }

    public function update(elapsed:Float, note:Note):Void //for note specific mods
    {
        //to be overridden
    }

    public function updateBeat(beat:Float):Void //for beat specific mods
    {
        //to be overridden
    }

    public function updateNotePosition(note:Note, data:NoteTransformData):Void //for note position specific mods
    {
        //to be overridden
    }

    public function updateStrum(strum:FlxSprite, data:NoteTransformData):Void //for strum specific mods
    {
        //to be overridden
    }

    public function shouldUpdateNote():Bool
    {
        return true;
    }

    public function shouldUpdateStrum():Bool
    {
        return true;
    }

    public function shouldUpdateBeat():Bool
    {
        return true;
    }

    public function shouldUpdateNotePosition():Bool
    {
        return true;
    }

    public function reset():Void
    {
        currentValue = baseValue;
        for (subVal in subValues.keys())
        {
            subValues.get(subVal).value = subValues.get(subVal).baseValue;
        }
    }

}
