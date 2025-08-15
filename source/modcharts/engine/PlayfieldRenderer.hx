package modcharts.engine;


import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.FlxStrip;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import openfl.geom.Vector3D;
import flixel.util.FlxSpriteUtil;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;

import flixel.FlxG;
import modcharts.modifiers.Modifier;
import modcharts.math.NotePositionData;
import modcharts.math.Playfield;
import modcharts.math.SustainStrip;
import flixel.system.FlxAssets.FlxShader;

import states.PlayState;
import objects.*;


using StringTools;

//a few todos im gonna leave here:

//setup quaternions for everything else (incoming angles and the rotate mod)
//do add and remove buttons on stacked events in editor
//fix switching event type in editor so you can actually do set events
//finish setting up tooltips in editor
//start documenting more stuff idk

typedef StrumNoteType = StrumNote;

class PlayfieldRenderer extends FlxSprite //extending flxsprite just so i can edit draw
{
    public var strumGroup:FlxTypedGroup<StrumNoteType>;
    public var notes:FlxTypedGroup<Note>;
    public var playStateInstance:PlayState;
    public var playfields:Array<Playfield> = []; //adding an extra playfield will add 1 for each player

    public var eventManager:ModchartEventManager;
    public var modifierTable:ModTable;
    public var tweenManager:FlxTweenManager;

    public var inEditor:Bool = false;
    public var editorPaused:Bool = false;

    public var speed:Float = 1.0;

    public var modifiers(get, default):Map<String, Modifier>;
    
    private function get_modifiers() : Map<String, Modifier>
    {
        return modifierTable.modifiers; //back compat with lua modcharts
    }


    public function new(strumGroup:FlxTypedGroup<StrumNoteType>, notes:FlxTypedGroup<Note>,instance:PlayState) 
    {
        super(0,0);
        this.strumGroup = strumGroup;
        this.notes = notes;
        if (Std.isOfType(instance, PlayState))
            playStateInstance = cast instance; //so it just casts once

        strumGroup.visible = false; //drawing with renderer instead
        notes.visible = false;

        // //fix stupid crash because the renderer in playstate is still technically null at this point and its needed for json loading
        //instance.modManager.renderer = this;

        tweenManager = new FlxTweenManager();
        eventManager = new ModchartEventManager(this);
        modifierTable = new ModTable(instance, this);
        addNewPlayfield(0,0,0);
    }


    public function addNewPlayfield(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?alpha:Float = 1)
    {
        playfields.push(new Playfield(x,y,z,alpha));
    }

    override function update(elapsed:Float) 
    {
        eventManager.update(elapsed);
        // 只在非暂停状态下更新tweenManager
        if (!playStateInstance.paused) {
            tweenManager.update(elapsed); //should be automatically paused when you pause in game
        }
        super.update(elapsed);
    }


    override public function draw()
    {
        if (alpha == 0 || !visible)
            return;

        strumGroup.cameras = this.cameras;
        notes.cameras = this.cameras;
        
        drawStuff(getNotePositions());
        //draw notes to screen
    }


    private function addDataToStrum(strumData:NotePositionData, strum:FlxSprite)
    {
        strum.x = strumData.x;
        strum.y = strumData.y;
        //strum.z = strumData.z;
        strum.angle = strumData.angle;
        strum.alpha = strumData.alpha;
        strum.scale.x = strumData.scaleX;
        strum.scale.y = strumData.scaleY;
    }

    private function getDataForStrum(i:Int, pf:Int)
    {
        var strumX = NoteMovement.defaultStrumX[i];
        var strumY = NoteMovement.defaultStrumY[i];
        var strumZ = 0;
        var strumScaleX = NoteMovement.defaultScale[i];
        var strumScaleY = NoteMovement.defaultScale[i];
        if (ModchartUtil.getIsPixelStage(playStateInstance))
        {
            //work on pixel stages
            strumScaleX = 1*PlayState.daPixelZoom;
            strumScaleY = 1*PlayState.daPixelZoom;
        }
        var strumData:NotePositionData = NotePositionData.get();
        strumData.setupStrum(strumX, strumY, strumZ, i, strumScaleX, strumScaleY, pf);
        playfields[pf].applyOffsets(strumData);
        modifierTable.applyStrumMods(strumData, i, pf);
        return strumData;
    }

   

    private function addDataToNote(noteData:NotePositionData, daNote:Note)
    {
        daNote.x = noteData.x;
        daNote.y = noteData.y;
        daNote.z = noteData.z;
        daNote.angle = noteData.angle;
        daNote.alpha = noteData.alpha;
        daNote.scale.x = noteData.scaleX;
        daNote.scale.y = noteData.scaleY;
    }
    private function createDataFromNote(noteIndex:Int, playfieldIndex:Int, curPos:Float, noteDist:Float, incomingAngle:Array<Float>)
    {
        var noteX = notes.members[noteIndex].x;
        var noteY = notes.members[noteIndex].y;
        var noteZ = notes.members[noteIndex].z;
        var lane = getLane(noteIndex);
        var noteScaleX = NoteMovement.defaultScale[lane];
        var noteScaleY = NoteMovement.defaultScale[lane];

        var noteAlpha:Float = 1;
        noteAlpha = notes.members[noteIndex].multAlpha;

        if (ModchartUtil.getIsPixelStage(playStateInstance))
        {
            //work on pixel stages
            noteScaleX = 1*PlayState.daPixelZoom;
            noteScaleY = 1*PlayState.daPixelZoom;
        }

        var noteData:NotePositionData = NotePositionData.get();
        noteData.setupNote(noteX, noteY, noteZ, lane, noteScaleX, noteScaleY, playfieldIndex, noteAlpha, 
            curPos, noteDist, incomingAngle[0], incomingAngle[1], notes.members[noteIndex].strumTime, noteIndex);
        playfields[playfieldIndex].applyOffsets(noteData);

        return noteData;
    }

    private function getNoteCurPos(noteIndex:Int, strumTimeOffset:Float = 0)
    {
        if (notes.members[noteIndex].isSustainNote && ModchartUtil.getDownscroll(playStateInstance))
            strumTimeOffset -= Std.int(Conductor.stepCrochet/getCorrectScrollSpeed()); //psych does this to fix its sustains but that breaks the visuals so basically reverse it back to normal

        var distance = (Conductor.songPosition - notes.members[noteIndex].strumTime) + strumTimeOffset;
        return distance*getCorrectScrollSpeed();
    }
    private function getLane(noteIndex:Int)
    {
        return (notes.members[noteIndex].mustPress ? notes.members[noteIndex].noteData+NoteMovement.keyCount : notes.members[noteIndex].noteData);
    }
    private function getNoteDist(noteIndex:Int)
    {
        var noteDist = -0.45;
        if (ModchartUtil.getDownscroll(playStateInstance))
            noteDist *= -1;
        return noteDist;
    }


    private function getNotePositions()
    {
        var notePositions:Array<NotePositionData> = [];
        for (pf in 0...playfields.length)
        {
            for (i in 0...strumGroup.members.length)
            {
                var strumData = getDataForStrum(i, pf);
                notePositions.push(strumData);
            }
            for (i in 0...notes.members.length)
            {
                var songSpeed = getCorrectScrollSpeed();

                var lane = getLane(i);

                var noteDist = getNoteDist(i);
                noteDist = modifierTable.applyNoteDistMods(noteDist, lane, pf);
                

                var sustainTimeThingy:Float = 0;

                //just causes too many issues lol, might fix it at some point
                /*if (notes.members[i].animation.curAnim.name.endsWith('end') && ClientPrefs.downScroll)
                {
                    if (noteDist > 0)
                        sustainTimeThingy = (NoteMovement.getFakeCrochet()/4)/2; //fix stretched sustain ends (downscroll)
                    //else 
                        //sustainTimeThingy = (-NoteMovement.getFakeCrochet()/4)/songSpeed;
                }*/
                    
                var curPos = getNoteCurPos(i, sustainTimeThingy);
                curPos = modifierTable.applyCurPosMods(lane, curPos, pf);

                if ((notes.members[i].wasGoodHit || (notes.members[i].prevNote.wasGoodHit)) && curPos >= 0 && notes.members[i].isSustainNote)
                    curPos = 0; //sustain clip

                var incomingAngle:Array<Float> = modifierTable.applyIncomingAngleMods(lane, curPos, pf);
                if (noteDist < 0)
                    incomingAngle[0] += 180; //make it match for both scrolls
                    
                //get the general note path
                NoteMovement.setNotePath(notes.members[i], lane, songSpeed, curPos, noteDist, incomingAngle[0], incomingAngle[1]);

                //save the position data
                var noteData = createDataFromNote(i, pf, curPos, noteDist, incomingAngle);

                //add offsets to data with modifiers
                modifierTable.applyNoteMods(noteData, lane, curPos, pf);

                //add position data to list
                notePositions.push(noteData);
            }
        }
        //sort by z before drawing
        notePositions.sort(function(a, b){
            if (a.z < b.z)
                return -1;
            else if (a.z > b.z)
                return 1;
            else
                return 0;
        });
        return notePositions;
    }

    private function drawStrum(noteData:NotePositionData)
    {
        if (noteData.alpha <= 0)
            return;
        var strumNote = strumGroup.members[noteData.index];
        var thisNotePos = ModchartUtil.calculatePerspective(new Vector3D(noteData.x+(strumNote.width/2), noteData.y+(strumNote.height/2), noteData.z*0.001), 
        ModchartUtil.defaultFOV*(Math.PI/180), -(strumNote.width/2), -(strumNote.height/2));

        noteData.x = thisNotePos.x;
        noteData.y = thisNotePos.y;
        noteData.scaleX *= (1/-thisNotePos.z);
        noteData.scaleY *= (1/-thisNotePos.z);

        addDataToStrum(noteData, strumGroup.members[noteData.index]); //set position and stuff before drawing
        strumGroup.members[noteData.index].cameras = this.cameras;

        strumGroup.members[noteData.index].draw();
    }
    private function drawNote(noteData:NotePositionData)
    {
        if (noteData.alpha <= 0)
            return;
        var daNote = notes.members[noteData.index];
        var thisNotePos = ModchartUtil.calculatePerspective(new Vector3D(noteData.x+(daNote.width/2)+ModchartUtil.getNoteOffsetX(daNote), noteData.y+(daNote.height/2), noteData.z*0.001), 
        ModchartUtil.defaultFOV*(Math.PI/180), -(daNote.width/2), -(daNote.height/2));

        noteData.x = thisNotePos.x;
        noteData.y = thisNotePos.y;
        noteData.scaleX *= (1/-thisNotePos.z);
        noteData.scaleY *= (1/-thisNotePos.z);
        //set note position using the position data
        addDataToNote(noteData, notes.members[noteData.index]); 
        //make sure it draws on the correct camera
        notes.members[noteData.index].cameras = this.cameras;
        //draw it
        notes.members[noteData.index].draw();
    }
    private function drawSustainNote(noteData:NotePositionData)
    {
        // 提前返回，如果alpha为0则不需要绘制
        if (noteData.alpha <= 0)
            return;
    
        var daNote = notes.members[noteData.index];
        // 如果mesh不存在，则创建
        if (daNote.mesh == null)
            daNote.mesh = new SustainStrip(daNote);
    
        // 设置scrollFactor和alpha
        daNote.mesh.scrollFactor.x = daNote.scrollFactor.x;
        daNote.mesh.scrollFactor.y = daNote.scrollFactor.y;
        daNote.alpha = noteData.alpha;
        daNote.mesh.alpha = daNote.alpha;
    
        // 获取歌曲速度，这个值可能在同一帧内多次调用时不变，但这里我们假设每次调用都需要最新的
        var songSpeed = getCorrectScrollSpeed();
        var lane = noteData.lane;
        
        // 计算y偏移量，这个值在同一个lane下是固定的，可以考虑缓存，但这里我们直接计算
        var yOffsetThingy = NoteMovement.arrowSizes[lane] * 0.5;
    
        // 计算当前音符位置
        var thisNotePos = ModchartUtil.calculatePerspective(
            new Vector3D(
                noteData.x + (daNote.width * 0.5) + ModchartUtil.getNoteOffsetX(daNote),
                noteData.y + yOffsetThingy,
                noteData.z * 0.001
            ),
            ModchartUtil.defaultFOV * (Math.PI / 180),
            -(daNote.width * 0.5),
            yOffsetThingy - yOffsetThingy // 注意：这里原代码是 yOffsetThingy - (NoteMovement.arrowSizes[noteData.lane]/2) 等于 yOffsetThingy - yOffsetThingy = 0
        );
        // 修正：原代码中最后一个参数是 yOffsetThingy - (NoteMovement.arrowSizes[noteData.lane]/2) 即0，所以这里直接写0
        // 但为了保持原意，我们还是按照原代码计算，因为yOffsetThingy就是NoteMovement.arrowSizes[lane]/2，所以减去自己就是0。
    
        // 计算时间间隔
        var crochet = ModchartUtil.getFakeCrochet();
        var timeToNextSustain = crochet * 0.25;
        if (noteData.noteDist < 0)
            timeToNextSustain = -timeToNextSustain; // 修正上滚
    
        // 计算下一个半音符位置和下一个音符位置
        var nextHalfNotePos = getSustainPoint(noteData, timeToNextSustain * 0.5);
        var nextNotePos = getSustainPoint(noteData, timeToNextSustain);
    
        // 计算角度并归一化到0-360
        var fixedAngY = noteData.incomingAngleY % 360;
        if (fixedAngY < 0) fixedAngY += 360;
    
        // 判断是否需要反转裁剪
        var reverseClip = (fixedAngY > 90 && fixedAngY < 270);
    
        // 判断是否需要翻转图形
        var flipGraphic = false;
        var isDownscroll = ModchartUtil.getDownscroll(playStateInstance);
        if (noteData.noteDist > 0) // 下滚
        {
            if (!isDownscroll)
                flipGraphic = true;
        }
        else // 上滚
        {
            if (isDownscroll)
                flipGraphic = true;
        }
    
        // 构造顶点并绘制
        daNote.mesh.constructVertices(noteData, thisNotePos, nextHalfNotePos, nextNotePos, flipGraphic, reverseClip);
        daNote.mesh.cameras = this.cameras;
        daNote.mesh.draw();
    }
    private function drawStuff(notePositions:Array<NotePositionData>)
    {
        for (noteData in notePositions)
        {
            if (noteData.isStrum) //draw strum
                drawStrum(noteData);
            else if (!notes.members[noteData.index].isSustainNote) //draw regular note
                drawNote(noteData);
            else //draw sustain
                drawSustainNote(noteData);

        }
    }

    function getSustainPoint(noteData:NotePositionData, timeOffset:Float):NotePositionData
    {
        var daNote:Note = notes.members[noteData.index];
        var songSpeed:Float = getCorrectScrollSpeed();
        var lane:Int = noteData.lane;
        var pf:Int = noteData.playfieldIndex;

        var noteDist:Float = getNoteDist(noteData.index);
        var curPos:Float = getNoteCurPos(noteData.index, timeOffset);
    
        curPos = modifierTable.applyCurPosMods(lane, curPos, pf);

        if ((daNote.wasGoodHit || (daNote.prevNote.wasGoodHit)) && curPos >= 0)
            curPos = 0;
        noteDist = modifierTable.applyNoteDistMods(noteDist, lane, pf);
        var incomingAngle:Array<Float> = modifierTable.applyIncomingAngleMods(lane, curPos, pf);
        if (noteDist < 0)
            incomingAngle[0] += 180; //make it match for both scrolls
        //get the general note path for the next note
        NoteMovement.setNotePath(daNote, lane, songSpeed, curPos, noteDist, incomingAngle[0], incomingAngle[1]);
        //save the position data 
        var noteData = createDataFromNote(noteData.index, pf, curPos, noteDist, incomingAngle);
        //add offsets to data with modifiers
        modifierTable.applyNoteMods(noteData, lane, curPos, pf);
        var yOffsetThingy = (NoteMovement.arrowSizes[lane]/2);
        var finalNotePos = ModchartUtil.calculatePerspective(new Vector3D(noteData.x+(daNote.width/2)+ModchartUtil.getNoteOffsetX(daNote), noteData.y+(NoteMovement.arrowSizes[noteData.lane]/2), noteData.z*0.001), 
        ModchartUtil.defaultFOV*(Math.PI/180), -(daNote.width/2), yOffsetThingy-(NoteMovement.arrowSizes[noteData.lane]/2));

        noteData.x = finalNotePos.x;
        noteData.y = finalNotePos.y;
        noteData.z = finalNotePos.z;

        return noteData;
    }

    public function getCorrectScrollSpeed()
    {
            return ModchartUtil.getScrollSpeed(playStateInstance);
    }

}
