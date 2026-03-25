package backend;

import lime.app.Application;
import lime.graphics.Image;
import flixel.util.FlxColor;

class AmbientMode
{

	public static var isInPlayState:Bool = false;

	static var frameCount:Int = 0;
	static var currentR:Int = -1;
	static var currentG:Int = -1;
	static var currentB:Int = -1;
	static var targetR:Int = 0;
	static var targetG:Int = 0;
	static var targetB:Int = 0;
	static var wasActive:Bool = false;

	static inline var SAMPLE_INTERVAL:Int = 30;
	static inline var LERP_SPEED:Float = 3.0;
	static inline var EDGE_STEP:Int = 40;

	public static function update(elapsed:Float):Void
	{
		#if (cpp && windows)
		if (!ClientPrefs.data.ambientMode || !isInPlayState)
		{
			if (wasActive)
			{
				wasActive = false;
				currentR = currentG = currentB = -1;
				targetR = targetG = targetB = 0;
				Native.applyWindowColorMode(ClientPrefs.data.windowColorMode);
			}
			return;
		}

		wasActive = true;
		frameCount++;

		if (frameCount % SAMPLE_INTERVAL == 0)
			sampleScreenColor();

		var t = Math.min(elapsed * LERP_SPEED, 1.0);
		var newR = Std.int((currentR < 0 ? targetR : currentR) + (targetR - (currentR < 0 ? targetR : currentR)) * t);
		var newG = Std.int((currentG < 0 ? targetG : currentG) + (targetG - (currentG < 0 ? targetG : currentG)) * t);
		var newB = Std.int((currentB < 0 ? targetB : currentB) + (targetB - (currentB < 0 ? targetB : currentB)) * t);

		if (newR != currentR || newG != currentG || newB != currentB)
		{
			currentR = newR;
			currentG = newG;
			currentB = newB;
			Native.setWindowCaptionColor(currentR, currentG, currentB);
		}
		#end
	}

	public static function reset():Void
	{
		#if (cpp && windows)
		isInPlayState = false;
		wasActive = false;
		currentR = currentG = currentB = -1;
		targetR = targetG = targetB = 0;
		Native.applyWindowColorMode(ClientPrefs.data.windowColorMode);
		#end
	}

	static function sampleScreenColor():Void
	{
		var window = Application.current.window;
		if (window != null)
		{
			var image:Image = null;
			try { image = window.readPixels(); } catch (_:Dynamic) {}

			if (image != null && image.data != null && image.width > 2 && image.height > 2)
			{
				readFromImage(image);
				return;
			}
		}

		var col:FlxColor = FlxG.camera.bgColor;
		targetR = col.red;
		targetG = col.green;
		targetB = col.blue;
		applyMinBrightness();
	}

	static function readFromImage(image:Image):Void
	{
		var data  = image.data;
		var imgW  = image.width;
		var imgH  = image.height;
		var step  = EDGE_STEP;
		var r = 0, g = 0, b = 0, count = 0;

		var x = 0;
		while (x < imgW)
		{
			var topIdx = x * 4;
			r += data[topIdx];     g += data[topIdx + 1]; b += data[topIdx + 2];

			var botIdx = ((imgH - 1) * imgW + x) * 4;
			r += data[botIdx];     g += data[botIdx + 1]; b += data[botIdx + 2];

			count += 2;
			x += step;
		}

		var y = step;
		while (y < imgH - step)
		{
			var leftIdx  = y * imgW * 4;
			r += data[leftIdx];    g += data[leftIdx + 1];  b += data[leftIdx + 2];

			var rightIdx = (y * imgW + imgW - 1) * 4;
			r += data[rightIdx];   g += data[rightIdx + 1]; b += data[rightIdx + 2];

			count += 2;
			y += step;
		}

		if (count == 0) return;

		targetR = Std.int(r / count);
		targetG = Std.int(g / count);
		targetB = Std.int(b / count);
		applyMinBrightness();
	}

	static inline function applyMinBrightness():Void
	{
		var minBright = 20;
		if (targetR < minBright && targetG < minBright && targetB < minBright)
			targetR = targetG = targetB = minBright;
	}
}
