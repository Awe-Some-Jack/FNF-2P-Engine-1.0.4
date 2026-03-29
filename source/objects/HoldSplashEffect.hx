package objects;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import objects.Note;
import backend.ClientPrefs;
import backend.Paths;
import shaders.RGBPalette;
import states.PlayState;

class HoldSplashEffect extends FlxGroup
{
	public var holdSplashMap:Map<String, FlxSprite> = new Map();
	public var holdSplashRgbMap:Map<FlxSprite, RGBPalette> = new Map();
	public var splashNoteMap:Map<FlxSprite, Note> = new Map();
	public var holdLastTails:Map<FlxSprite, Note> = new Map();
	public var holdAliveTimers:Map<FlxSprite, Float> = new Map();
	public var colors:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];
	static inline var ALIVE_TIMEOUT:Float = 0.1;

	public function new()
	{
		super();
		var isPixel = PlayState.isPixelStage;
		var path = isPixel ? 'holdCover/holdCoverPixelRGB' : 'holdCover/holdCoverRGB';

		for (color in colors)
		{
			add(createHoldSplash(color, "BF", path, isPixel));
			add(createHoldSplash(color, "DAD", path, isPixel));
		}

		initRGBShaders();
	}

	function createHoldSplash(color:String, suffix:String, path:String, isPixel:Bool):FlxSprite
	{
		var id = 'hold' + color + suffix;
		var fps = isPixel ? 33 : 24;

		var splash = new FlxSprite();
		splash.frames = Paths.getSparrowAtlas(path);
		splash.animation.addByPrefix('hold', 'holdCoverRGB', fps, true);
		splash.animation.addByPrefix('end', 'holdCoverEndRGB', fps, false);
		splash.visible = false;
		splash.cameras = [PlayState.instance.camHUD];
		splash.antialiasing = ClientPrefs.data.antialiasing && !isPixel;
		splash.scrollFactor.set(0, 0);
		if (isPixel) splash.scale.set(6, 6);
		splash.animation.play('hold', true);
		holdSplashMap.set(id, splash);

		var rgb = new RGBPalette();
		splash.shader = rgb.shader;
		holdSplashRgbMap.set(splash, rgb);

		return splash;
	}

	function initRGBShaders():Void
	{
		var strums = PlayState.instance.strumLineNotes;
		if (strums == null) return;

		for (i in 0...colors.length)
		{
			var color = colors[i];
			for (isOpponent in [true, false])
			{
				var suffix = isOpponent ? 'DAD' : 'BF';
				var strumIndex = isOpponent ? i : i + 4;

				var splash = holdSplashMap.get('hold' + color + suffix);
				var rgb = holdSplashRgbMap.get(splash);
				if (splash == null || rgb == null) continue;
				if (strums.members.length <= strumIndex) continue;

				var strum = strums.members[strumIndex];
				if (strum == null || strum.rgbShader == null) continue;

				rgb.r = strum.rgbShader.r;
				rgb.g = strum.rgbShader.g;
				rgb.b = strum.rgbShader.b;
			}
		}
	}

	function setSplashPosition(splash:FlxSprite, strum:FlxSprite, isOpponent:Bool, noteData:Int, ?note:Note):Void
	{
		if (note != null)
			splash.angle = note.angle;
		else if (strum != null)
			splash.angle = strum.angle;
		else
			splash.angle = 0;

		if (isOpponent)
		{
			if (ClientPrefs.data.middleScroll)
				splash.x = strum.x + [-50, -50, 50, 50][noteData];
			else
				splash.x = strum.x - 105;

			var strumIndex = isOpponent ? noteData : noteData + 4;
			if (PlayState.instance.strumLineNotes.members.length > strumIndex)
				splash.alpha = PlayState.instance.strumLineNotes.members[strumIndex].alpha;
		}
		else
		{
			splash.x = strum.x - 105;
		}

		if (PlayState.isPixelStage)
			splash.y = strum.y - 125;
		else
			splash.y = strum.y - 100;
	}

	public function triggerSplash(isOpponent:Bool, noteData:Int, ?note:Note):Void
	{
		if (noteData < 0 || noteData >= colors.length) return;

		var color = colors[noteData];
		var splash = holdSplashMap.get('hold' + color + (isOpponent ? 'DAD' : 'BF'));
		if (splash == null) return;
		var strumIndex = isOpponent ? noteData : noteData + 4;
		if (PlayState.instance.strumLineNotes.members.length > strumIndex)
		{
			var strum = PlayState.instance.strumLineNotes.members[strumIndex];
			if (strum != null)
				setSplashPosition(splash, strum, isOpponent, noteData, note);
		}

		holdAliveTimers.set(splash, 0);
		if (note != null) splashNoteMap.set(splash, note);
		if (note != null && !holdLastTails.exists(splash))
		{
			var lastTail:Note = null;
			if (note.isSustainNote && note.parent != null && note.parent.tail.length > 0)
				lastTail = note.parent.tail[note.parent.tail.length - 1];
			else if (!note.isSustainNote && note.tail.length > 0)
				lastTail = note.tail[note.tail.length - 1];

			if (lastTail != null)
				holdLastTails.set(splash, lastTail);
		}

		if (noteData < Note.globalRgbShaders.length && Note.globalRgbShaders[noteData] != null)
		{
			var rgb = holdSplashRgbMap.get(splash);
			if (rgb != null)
				rgb.copyValues(Note.globalRgbShaders[noteData]);
		}

		if (splash.animation.curAnim == null || splash.animation.curAnim.name != 'hold')
			splash.animation.play('hold', true);

		splash.visible = true;
	}

	public function hideSplash(noteData:Int, isOpponent:Bool):Void
	{
		if (noteData < 0 || noteData >= colors.length) return;
		var color = colors[noteData];
		var splash = holdSplashMap.get('hold' + color + (isOpponent ? 'DAD' : 'BF'));
		if (splash == null) return;

		splashNoteMap.remove(splash);
		holdLastTails.remove(splash);
		holdAliveTimers.remove(splash);

		if (isOpponent)
		{
			splash.visible = false;
			splash.animation.play('hold', true);
		}
		else if (splash.visible && splash.animation.curAnim != null && splash.animation.curAnim.name == 'hold')
			splash.animation.play('end', true);
	}

	public function forceHideSplash(noteData:Int, isOpponent:Bool):Void
	{
		if (noteData < 0 || noteData >= colors.length) return;
		var color = colors[noteData];
		var splash = holdSplashMap.get('hold' + color + (isOpponent ? 'DAD' : 'BF'));
		if (splash == null) return;

		splash.visible = false;
		if (splash.animation != null) splash.animation.play('hold', true);
		splashNoteMap.remove(splash);
		holdLastTails.remove(splash);
		holdAliveTimers.remove(splash);
	}

	public function forceHideAll(isOpponent:Bool):Void
	{
		for (i in 0...colors.length)
			forceHideSplash(i, isOpponent);
	}

	function doEndSplash(splash:FlxSprite, isOpponent:Bool):Void
	{
		splashNoteMap.remove(splash);
		holdLastTails.remove(splash);
		holdAliveTimers.remove(splash);
		if (isOpponent)
		{
			splash.visible = false;
			splash.animation.play('hold', true);
		}
		else if (splash.animation.curAnim != null && splash.animation.curAnim.name == 'hold')
			splash.animation.play('end', true);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		for (i in 0...4)
		{
			for (isOpponent in [false, true])
			{
				var color = colors[i];
				var splash = holdSplashMap.get('hold' + color + (isOpponent ? 'DAD' : 'BF'));
				var strumIndex = isOpponent ? i : i + 4;

				if (splash == null || !splash.visible) continue;

				if (PlayState.instance.strumLineNotes.members.length > strumIndex)
				{
					var strum = PlayState.instance.strumLineNotes.members[strumIndex];
					if (strum != null)
					{
						var linkedNote = splashNoteMap.get(splash);
						setSplashPosition(splash, strum, isOpponent, i, linkedNote);
						if (linkedNote != null)
							splash.alpha = strum.alpha;
							// splash.cameras = strum.cameras;
							// splash.scrollFactor.set(strum.scrollFactor.x, strum.scrollFactor.y);
					}
				}

				if (splash.animation.curAnim != null && splash.animation.curAnim.name == 'hold')
				{
					var lastTail = holdLastTails.get(splash);
					if (lastTail != null && !lastTail.exists)
					{
						doEndSplash(splash, isOpponent);
						continue;
					}
					if (holdAliveTimers.exists(splash))
					{
						var t = holdAliveTimers.get(splash);
						if (t == null) t = 0;
						t += elapsed;
						holdAliveTimers.set(splash, t);

						if (t > ALIVE_TIMEOUT)
						{
							doEndSplash(splash, isOpponent);
							continue;
						}
					}
				}

				if (splash.animation.curAnim != null
					&& splash.animation.curAnim.name == 'end'
					&& splash.animation.finished)
				{
					splash.visible = false;
					splash.animation.play('hold', true);
					splashNoteMap.remove(splash);
					holdLastTails.remove(splash);
					holdAliveTimers.remove(splash);
				}
			}
		}
	}
}
