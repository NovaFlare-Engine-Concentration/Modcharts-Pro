package modcharts;

import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import modcharts.core.Modifier;
import modcharts.transform.NoteTransform;
import modcharts.render.GPURenderSystem;
#if LEATHER
import game.Conductor;
#end

class ModifierManager
{
    public var modifiers:Map<String, Modifier> = new Map<String, Modifier>();
    private var instance:ModchartMusicBeatState = null;
    private var renderer:PlayfieldSystem = null;
    public var gpuRenderer:GPURenderSystem = null;
    public var useGPU:Bool = true;

    //The table is used to precalculate all the playfield and lane checks on each modifier,
    //so it should end up with a lot less loops and if checks each frame
    //index table by playfield, then lane, and then loop through each modifier
    private var table:Array<Array<Array<Modifier>>> = [];

    public function new(instance:ModchartMusicBeatState, renderer:PlayfieldSystem)
    {
        this.instance = instance;
        this.renderer = renderer;
        
        // 初始化GPU渲染系统
        if (GPURenderSystem.isGPUSupported())
        {
            gpuRenderer = new GPURenderSystem();
            useGPU = gpuRenderer.enabled;
        }
        else
        {
            useGPU = false;
            trace("GPU渲染不可用，将使用CPU渲染");
        }
        
        loadDefaultModifiers();
        reconstructTable();
    }

    public function add(mod:Modifier) : Void
    {
        mod.instance = instance;
        mod.renderer = renderer;
        remove(mod.tag); //in case you replace one???
        modifiers.set(mod.tag, mod);
    }

    public function remove(tag:String) : Void
    {
        if (modifiers.exists(tag))
            modifiers.remove(tag);
    }

    public function clear() : Void
    {
        modifiers.clear();

        loadDefaultModifiers();
        
        // 清除GPU缓存
        if (gpuRenderer != null)
        {
            gpuRenderer.clearCache();
        }
    }

    public function resetMods() : Void
    {
        for (mod in modifiers)
        {
            mod.currentValue = mod.baseValue;
            for (subVal in mod.subValues.keys())
            {
                mod.subValues.get(subVal).value = mod.subValues.get(subVal).baseValue;
            }
        }
    }

    public function reconstructTable() : Void
    {
        table = []; //reset table

        var playfieldCount = renderer.playfields.length;
        for (pf in 0...playfieldCount)
        {
            table.push([]);
            for (lane in 0...NoteTransform.totalKeyCount)
            {
                table[pf].push([]);
                for (mod in modifiers)
                {
                    if (mod.playfield == -1 || mod.playfield == pf) //playfield check
                    {
                        if (mod.targetLane == -1 || mod.targetLane == lane) //lane check
                        {
                            if (mod.type == ALL || 
                                (mod.type == PLAYERONLY && lane >= NoteTransform.keyCount) || 
                                (mod.type == OPPONENTONLY && lane < NoteTransform.keyCount) ||
                                (mod.type == LANESPECIFIC && mod.targetLane == lane))
                            {
                                table[pf][lane].push(mod);
                            }
                        }
                    }
                }
            }
        }
    }

    public function getModsForNote(noteData:NoteTransformData) : Array<Modifier>
    {
        if (noteData.playfieldIndex >= table.length || noteData.lane >= table[0].length)
            return [];

        var mods = table[noteData.playfieldIndex][noteData.lane];
        
        // 如果使用GPU渲染，更新变换数据
        if (useGPU && gpuRenderer != null)
        {
            var noteDataArray:Array<NoteTransformData> = [noteData];
            gpuRenderer.updateTransforms(noteDataArray);
        }
        
        return mods;
    }

    public function getModsForPlayfield(pf:Int) : Array<Modifier>
    {
        var mods:Array<Modifier> = [];
        if (pf >= table.length)
            return mods;

        for (lane in 0...table[pf].length)
        {
            for (mod in table[pf][lane])
            {
                if (!mods.contains(mod))
                    mods.push(mod);
            }
        }
        return mods;
    }

    public function getModsForLane(lane:Int) : Array<Modifier>
    {
        var mods:Array<Modifier> = [];
        if (table.length == 0 || lane >= table[0].length)
            return mods;

        for (pf in 0...table.length)
        {
            for (mod in table[pf][lane])
            {
                if (!mods.contains(mod))
                    mods.push(mod);
            }
        }
        return mods;
    }

    public function getMod(tag:String) : Modifier
    {
        if (modifiers.exists(tag))
            return modifiers.get(tag);
        return null;
    }

    private function loadDefaultModifiers() : Void
    {
        //xmods
        add(new Modifier("x", ALL, -1));
        add(new Modifier("reverse", ALL, -1));
        add(new Modifier("split", ALL, -1));
        add(new Modifier("alternate", ALL, -1));
        add(new Modifier("cross", ALL, -1));
        add(new Modifier("centered", ALL, -1));

        //ymods
        add(new Modifier("downscroll", ALL, -1));
        add(new Modifier("upsidescroll", ALL, -1));
        add(new Modifier("tornado", ALL, -1));
        add(new Modifier("drunk", ALL, -1));
        add(new Modifier("tipsy", ALL, -1));
        add(new Modifier("bumpy", ALL, -1));
        add(new Modifier("beat", ALL, -1));

        //zmods
        add(new Modifier("mini", ALL, -1));
        add(new Modifier("zoom", ALL, -1));
        add(new Modifier("wavy", ALL, -1));
        add(new Modifier("wiggle", ALL, -1));
        add(new Modifier("stereo", ALL, -1));
        add(new Modifier("flip", ALL, -1));
        add(new Modifier("invert", ALL, -1));

        //rotation mods
        add(new Modifier("rotate", ALL, -1));
        add(new Modifier("confusion", ALL, -1));
        add(new Modifier("dizzy", ALL, -1));
        add(new Modifier("tornado", ALL, -1));
        add(new Modifier("roll", ALL, -1));

        //special mods
        add(new Modifier("stealth", ALL, -1));
        add(new Modifier("blink", ALL, -1));
        add(new Modifier("hidden", ALL, -1));
        add(new Modifier("sudden", ALL, -1));
        add(new Modifier("vanish", ALL, -1));

        //subvalues for xmods
        getMod("x").subValues.set("offsetX", new Modifier.ModifierSubValue(0));
        getMod("reverse").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("split").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("alternate").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("cross").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("centered").subValues.set("mult", new Modifier.ModifierSubValue(1));

        //subvalues for ymods
        getMod("downscroll").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("upsidescroll").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("tornado").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("drunk").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("tipsy").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("bumpy").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("beat").subValues.set("mult", new Modifier.ModifierSubValue(1));

        //subvalues for zmods
        getMod("mini").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("zoom").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("wavy").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("wiggle").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("stereo").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("flip").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("invert").subValues.set("mult", new Modifier.ModifierSubValue(1));

        //subvalues for rotation mods
        getMod("rotate").subValues.set("speed", new Modifier.ModifierSubValue(0));
        getMod("rotate").subValues.set("angle", new Modifier.ModifierSubValue(0));
        getMod("confusion").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("dizzy").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("tornado").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("roll").subValues.set("mult", new Modifier.ModifierSubValue(1));

        //subvalues for special mods
        getMod("stealth").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("blink").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("hidden").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("sudden").subValues.set("mult", new Modifier.ModifierSubValue(1));
        getMod("vanish").subValues.set("mult", new Modifier.ModifierSubValue(1));
    }
}