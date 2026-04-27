package backend;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

class GraphicCacheSprite extends FlxSprite
{
	public var cachedGraphics:Array<FlxGraphic> = [];
	public var nonRenderedCachedGraphics:Array<FlxGraphic> = [];

	public function new()
	{
		super();
		alpha = 0.00001;
		active = false;
		visible = true;
	}

	public function cache(path:String):Void
	{
		cacheGraphic(FlxG.bitmap.add(path));
	}

	public function cacheGraphic(graphic:FlxGraphic):Void
	{
		if (graphic == null || cachedGraphics.contains(graphic)) return;

		graphic.incrementUseCount();
		graphic.destroyOnNoUse = false;
		cachedGraphics.push(graphic);
		nonRenderedCachedGraphics.push(graphic);
	}

	override public function draw():Void
	{
		while (nonRenderedCachedGraphics.length > 0)
		{
			var graphic:FlxGraphic = nonRenderedCachedGraphics.shift();
			if (graphic == null || graphic.isDestroyed)
				continue;

			loadGraphic(graphic);
			drawComplex(FlxG.camera);
		}
	}

	override public function isOnScreen(?camera:FlxCamera):Bool
		return true;

	override public function destroy():Void
	{
		for (graphic in cachedGraphics)
		{
			if (graphic == null || graphic.isDestroyed) continue;
			graphic.destroyOnNoUse = true;
			graphic.decrementUseCount();
		}
		cachedGraphics = [];
		nonRenderedCachedGraphics = [];
		graphic = null;
		super.destroy();
	}
}
