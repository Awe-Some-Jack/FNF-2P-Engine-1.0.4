package debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import openfl.filters.DropShadowFilter;
import backend.ClientPrefs;

#if cpp
@:cppFileCode('
#include <windows.h>
#include <psapi.h>

extern "C" double getMemoryUsageMB() {
    PROCESS_MEMORY_COUNTERS pmc = {sizeof(pmc)};
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
        return pmc.WorkingSetSize / (1024.0 * 1024.0);
    return 0.0;
}
')
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		_font = openfl.Assets.getFont("assets/fonts/DungGeunMo.ttf");
		defaultTextFormat = new TextFormat(_font != null ? _font.fontName : "_sans", ClientPrefs.data.fpsTextSize, color);
		embedFonts = true;
		filters = [
			new DropShadowFilter(1, 0,   0x464646, 1, 0, 0),
			new DropShadowFilter(1, 90,  0x464646, 1, 0, 0),
			new DropShadowFilter(1, 180, 0x464646, 1, 0, 0),
			new DropShadowFilter(1, 270, 0x464646, 1, 0, 0),
		];
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
		alpha = ClientPrefs.data.fpsTextAlpha;

		times = [];
	}

	var _font:openfl.text.Font;

	public function applySettings():Void {
		var fmt = defaultTextFormat;
		fmt.size = ClientPrefs.data.fpsTextSize;
		defaultTextFormat = fmt;
		setTextFormat(fmt);
		alpha = ClientPrefs.data.fpsTextAlpha;
		_lastColor = -1; // force filter refresh
	}

	var deltaTimeout:Float = 0.0;
	var ramTimeout:Float = 0.0;
	var cachedMemStr:String = "";
	var _lastColor:Int = -1;

	inline function formatMemoryLabel(mem:Float):String
	{
		if (mem >= 1000)
			return '${FlxMath.roundDecimal(mem / 1000, 2)} GB';
		return '${FlxMath.roundDecimal(mem, 2)} MB';
	}

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();
		deltaTimeout += deltaTime;
		ramTimeout += deltaTime;
		if (deltaTimeout < 250) return;

		#if cpp
		if (ramTimeout >= 1000) {
			var appMem:Float = memoryMegas;
			var gcMem:Float = System.totalMemory / (1024.0 * 1024.0);
			cachedMemStr = '\nRAM: [APP: ${formatMemoryLabel(appMem)} / GC: ${formatMemoryLabel(gcMem)}]';
			ramTimeout = 0.0;
		}
		#end

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void { // so people can override it in hscript
		text = 'FPS: ${currentFPS} / ${FlxG.updateFramerate}${cachedMemStr}';

		if (currentFPS < FlxG.drawFramerate * 0.5)
			setColorWithOutline(0xFFFF0000, 0xFF5C0000);
		else
			setColorWithOutline(0xFFFFFFFF, 0xFF383838);
	}

	inline function setColorWithOutline(color:Int, outline:Int = 0x000000):Void {
		if (_lastColor == color) return;
		_lastColor = color;
		textColor = color;
		filters = [
			new DropShadowFilter(1, 0,   outline, 1, 0, 0),
			new DropShadowFilter(1, 90,  outline, 1, 0, 0),
			new DropShadowFilter(1, 180, outline, 1, 0, 0),
			new DropShadowFilter(1, 270, outline, 1, 0, 0),
		];
	}

	inline function get_memoryMegas():Float {
		#if cpp
		return untyped __global__.getMemoryUsageMB();
		#else
		return 0;
		#end
	}
}
