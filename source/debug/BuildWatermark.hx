package debug;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.filters.DropShadowFilter;
import openfl.events.Event;

class BuildWatermark extends Sprite
{
	public static var buildText:String = "ENGINE BUILD " + BuildDate.get() + " KST";

	var bg:Shape;
	var label:TextField;

	static inline var PAD_X:Int = 8;
	static inline var PAD_Y:Int = 4;

	public function new()
	{
		super();

		bg = new Shape();
		addChild(bg);

		label = new TextField();
		var font = openfl.Assets.getFont("assets/fonts/DungGeunMo.ttf");
		label.defaultTextFormat = new TextFormat(font != null ? font.fontName : "_sans", 16, 0xFFFFFF);
		label.embedFonts = true;
		label.selectable = false;
		label.mouseEnabled = false;
		label.autoSize = LEFT;
		label.multiline = false;
		label.filters = [
			new DropShadowFilter(1, 0,   0x000000, 0, 0),
			new DropShadowFilter(1, 90,  0x000000, 1, 0, 0),
			new DropShadowFilter(1, 180, 0x000000, 1, 0, 0),
			new DropShadowFilter(1, 270, 0x000000, 1, 0, 0),
		];
		label.text = buildText;
		label.x = PAD_X;
		label.y = PAD_Y;
		addChild(label);

		drawBg();
		repositionSelf();

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		stage.addEventListener(Event.RESIZE, onStageResize);
		repositionSelf();
	}

	private function onStageResize(e:Event):Void
	{
		repositionSelf();
	}

	private function drawBg():Void
	{
		var w:Float = label.textWidth + PAD_X * 2 + 4;
		var h:Float = label.textHeight + PAD_Y * 2;
		bg.graphics.clear();
		bg.graphics.beginFill(0x000000, 0.3);
		bg.graphics.drawRect(0, 0, w, h);
		bg.graphics.endFill();
	}

	private function repositionSelf():Void
	{
		var stageW:Float = openfl.Lib.current.stage != null ? openfl.Lib.current.stage.stageWidth  : 1280;
		var stageH:Float = openfl.Lib.current.stage != null ? openfl.Lib.current.stage.stageHeight : 720;
		var w:Float = label.textWidth + PAD_X * 2 + 4;
		var h:Float = label.textHeight + PAD_Y * 2;
		x = Math.round(stageW - w);
		y = Math.round(stageH - h);
	}

}
