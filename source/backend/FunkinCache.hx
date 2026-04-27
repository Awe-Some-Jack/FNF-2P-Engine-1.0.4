package backend;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.AssetCache;

#if lime
import lime.utils.Assets as LimeAssets;
#end

class FunkinCache extends AssetCache
{
	public static var instance:FunkinCache;

	@:noCompletion public var bitmapData2:Map<String, BitmapData>;
	@:noCompletion public var font2:Map<String, Font>;
	@:noCompletion public var sound2:Map<String, Sound>;

	public function new()
	{
		super();
		moveToSecondLayer();
		instance = this;
	}

	public static function init():Void
	{
		if (instance != null) return;

		openfl.utils.Assets.cache = new FunkinCache();
		FlxG.signals.preStateSwitch.add(function() instance.moveToSecondLayer());
		FlxG.signals.postStateSwitch.add(function() instance.clearSecondLayer());
	}

	public function moveToSecondLayer():Void
	{
		bitmapData2 = bitmapData;
		font2 = font;
		sound2 = sound;
		bitmapData = new Map();
		font = new Map();
		sound = new Map();
	}

	public function clearSecondLayer():Void
	{
		for (key => bitmap in bitmapData2)
		{
			FlxG.bitmap.removeByKey(key);
			#if lime
			LimeAssets.cache.image.remove(key);
			#end
		}

		#if lime
		for (key => fontData in font2)
			LimeAssets.cache.font.remove(key);
		for (key => soundData in sound2)
			LimeAssets.cache.audio.remove(key);
		#end

		bitmapData2 = new Map();
		font2 = new Map();
		sound2 = new Map();
	}

	public override function getBitmapData(id:String):BitmapData
	{
		var cached:BitmapData = bitmapData.get(id);
		if (cached != null) return cached;

		cached = bitmapData2.get(id);
		if (cached != null)
		{
			bitmapData2.remove(id);
			bitmapData.set(id, cached);
		}
		return cached;
	}

	public override function getFont(id:String):Font
	{
		var cached:Font = font.get(id);
		if (cached != null) return cached;

		cached = font2.get(id);
		if (cached != null)
		{
			font2.remove(id);
			font.set(id, cached);
		}
		return cached;
	}

	public override function getSound(id:String):Sound
	{
		var cached:Sound = sound.get(id);
		if (cached != null) return cached;

		cached = sound2.get(id);
		if (cached != null)
		{
			sound2.remove(id);
			sound.set(id, cached);
		}
		return cached;
	}

	public override function hasBitmapData(id:String):Bool
		return bitmapData.exists(id) || bitmapData2.exists(id);

	public override function hasFont(id:String):Bool
		return font.exists(id) || font2.exists(id);

	public override function hasSound(id:String):Bool
		return sound.exists(id) || sound2.exists(id);

	public override function removeBitmapData(id:String):Bool
	{
		#if lime
		LimeAssets.cache.image.remove(id);
		#end
		return bitmapData.remove(id) || bitmapData2.remove(id);
	}

	public override function removeFont(id:String):Bool
	{
		#if lime
		LimeAssets.cache.font.remove(id);
		#end
		return font.remove(id) || font2.remove(id);
	}

	public override function removeSound(id:String):Bool
	{
		#if lime
		LimeAssets.cache.audio.remove(id);
		#end
		return sound.remove(id) || sound2.remove(id);
	}
}
