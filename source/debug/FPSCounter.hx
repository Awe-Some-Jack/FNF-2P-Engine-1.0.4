package debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import openfl.filters.DropShadowFilter;

#if cpp
@:cppFileCode('
#include <windows.h>
#include <psapi.h>

extern "C" double getMemoryUsageMB() {
    PROCESS_MEMORY_COUNTERS_EX memInfo;
    if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&memInfo, sizeof(memInfo))) {
        return memInfo.WorkingSetSize / (1024.0 * 1024.0);
    }
    return -1;
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
		var font = openfl.Assets.getFont("assets/fonts/DungGeunMo.ttf");
		defaultTextFormat = new TextFormat(font != null ? font.fontName : "_sans", 15, color);
		embedFonts = true;
		filters = [
			new DropShadowFilter(1, 0,   0x000000, 1, 0, 0),
			new DropShadowFilter(1, 90,  0x000000, 1, 0, 0),
			new DropShadowFilter(1, 180, 0x000000, 1, 0, 0),
			new DropShadowFilter(1, 270, 0x000000, 1, 0, 0),
		];
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		
		updateText();
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void { // so people can override it in hscript
		var memStr:String = "";
		#if cpp
		var mem:Float = FlxMath.roundDecimal(memoryMegas, 1);
		if (mem >= 1000)
			memStr = '\nRAM: ${FlxMath.roundDecimal(mem / 1000, 2)} GB';
		else
			memStr = '\nRAM: ${mem} MB';
		#end

		text = 'FPS: ${currentFPS} / ${FlxG.updateFramerate}${memStr}';

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
	}

	inline function get_memoryMegas():Float {
		#if cpp
		return untyped __global__.getMemoryUsageMB();
		#else
		return 0;
		#end
	}
}
