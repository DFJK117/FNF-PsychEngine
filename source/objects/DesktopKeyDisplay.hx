package objects;

// ============================================================================
// Doubao Engine - DESKTOP physical-key indicator (NFE-style key light bar)
//
// A HUD-only row (two rows in two-player mode) of one circle per PHYSICAL key,
// laid out in keyboard order and labelled with the key name. While a key is
// held its circle lights up in the lane direction color and "pops" larger; on
// release it dims back down but the letter stays. A CPS + total-press counter
// is drawn in the top-right corner. Optional short key-click sound.
//
// This is a pure visual layer: it never drives judgement (the real keyboard
// handling in PlayState still does). Compiled ONLY on desktop targets.
// ============================================================================
#if desktop
import backend.DoubaoConfig;
import backend.InputFormatter;
import openfl.display.BitmapData;
import openfl.display.Shape;
import flixel.input.keyboard.FlxKey;

class DesktopKeyDisplay extends FlxTypedGroup<FlxSprite>
{
	// 0 = LEFT (purple), 1 = DOWN (blue), 2 = UP (green), 3 = RIGHT (red)
	static final DIR_COLOR:Array<Int> = [0xD949D9, 0x3A78E8, 0x37D64B, 0xE84848];

	var buttons:Array<KeyBtn> = [];
	var timeNow:Float = 0;
	var pressTimes:Array<Float> = [];
	public var totalPress:Int = 0;
	var stat:FlxText = null;
	var statTimer:Float = 0;

	public function new()
	{
		super();
		build();
	}

	function build():Void
	{
		final w:Float = FlxG.width > 0 ? FlxG.width : 1280;
		final h:Float = FlxG.height > 0 ? FlxG.height : 720;
		final twoP:Bool = DoubaoConfig.isTwoPlayer();

		var groups:Array<{cx:Float, keys:Array<FlxKey>}> = [];
		if (twoP)
		{
			// P1 (opponent Dad, WASD) on the left quarter, P2 (BF, arrows) on the right
			groups.push({cx: w * 0.25, keys: DoubaoConfig.P1_KEYS.copy()});
			groups.push({cx: w * 0.75, keys: DoubaoConfig.P2_KEYS.copy()});
		}
		else
		{
			// Solo (vanilla 4K or any 1K..61K layout): a single centered row
			groups.push({cx: w / 2, keys: DoubaoConfig.buildSoloBinds(DoubaoConfig.keyCount)});
		}

		for (grp in groups)
		{
			final n:Int = grp.keys.length;
			final avail:Float = twoP ? (w / 2 - 28) : (w - 150);
			var d:Float = avail / (n + 0.7);
			if (d > 46) d = 46;
			if (d < 13) d = 13; // keeps even a 61-key row legible
			final stride:Float = d * 1.16;
			final totalW:Float = stride * (n - 1);
			var x:Float = grp.cx - totalW / 2;
			final y:Float = h - d / 2 - 14;

			for (lane in 0...n)
			{
				final key:FlxKey = grp.keys[lane];
				final dir:Int = DoubaoConfig.directionOf(lane);

				final circ:FlxSprite = makeCircle(Std.int(d), DIR_COLOR[dir]);
				circ.x = x;
				circ.y = y;
				circ.alpha = 0.22; // dim at rest
				add(circ);

				final fs:Int = Std.int(Math.max(9, d * 0.42));
				final lbl:FlxText = new FlxText(x - d / 2, y - d / 2, d, shortName(key), fs);
				lbl.setFormat(Paths.font('vcr.ttf'), fs, FlxColor.WHITE, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				lbl.scrollFactor.set();
				lbl.centerOrigin();
				lbl.x = x;
				lbl.y = y;
				add(lbl);

				buttons.push({key: key, circ: circ, lbl: lbl, lit: false});
				x += stride;
			}
		}

		stat = new FlxText(w - 300, 8, 292, '', 16);
		stat.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, flixel.text.FlxTextAlign.RIGHT, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		stat.scrollFactor.set();
		add(stat);
		updateStat(true);
	}

	public function setCameras(cams:Array<FlxCamera>):Void
	{
		for (s in members)
		{
			if (s != null) s.cameras = cams;
		}
	}

	public function tick(elapsed:Float):Void
	{
		timeNow += elapsed;
		while (pressTimes.length > 0 && pressTimes[0] < timeNow - 1.0)
			pressTimes.shift();

		for (b in buttons)
		{
			final held:Bool = FlxG.keys.anyPressed([b.key]);
			if (held && !b.lit)
			{
				// rising edge: light up, count, click
				b.lit = true;
				b.circ.alpha = 1.0;
				b.circ.scale.set(1.15, 1.15); // press "pop"
				totalPress++;
				pressTimes.push(timeNow);
				if (ClientPrefs.data.doubaoKeySound)
					FlxG.sound.play(Paths.sound('db_keyclick'), 0.35);
			}
			else if (!held && b.lit)
			{
				// falling edge: dim back down, letter stays
				b.lit = false;
				b.circ.alpha = 0.22;
				b.circ.scale.set(1, 1);
			}
		}

		updateStat(false);
	}

	var statTimer:Float = 0;
	function updateStat(force:Bool):Void
	{
		statTimer -= 1 / 60;
		if (!force && statTimer > 0) return;
		statTimer = 0.1;
		if (stat != null)
			stat.text = 'CPS: ${pressTimes.length}   TOTAL: $totalPress';
	}

	function makeCircle(size:Int, color:Int):FlxSprite
	{
		final bmp:BitmapData = new BitmapData(size, size, true, 0x00000000);
		final shape:Shape = new Shape();
		shape.graphics.lineStyle(Math.max(2, Std.int(size * 0.07)), FlxColor.WHITE, 0.9);
		shape.graphics.beginFill(color, 1.0);
		shape.graphics.drawCircle(size / 2, size / 2, size / 2 - 2);
		shape.graphics.endFill();
		bmp.draw(shape);
		final spr:FlxSprite = new FlxSprite();
		spr.pixels = bmp; // set_pixels builds a single frame sized to the bitmap
		spr.centerOrigin();
		spr.scrollFactor.set();
		spr.antialiasing = true;
		return spr;
	}

	function shortName(k:FlxKey):String
	{
		var s:String = InputFormatter.getKeyName(k);
		if (s == null || s.length == 0) return '?';
		s = s.toUpperCase();
		switch (s)
		{
			case 'SPACE': return 'SPC';
			case 'LEFT': return 'L';
			case 'DOWN': return 'D';
			case 'UP': return 'U';
			case 'RIGHT': return 'R';
			default: {}
		}
		if (s.length > 4) s = s.substr(0, 4);
		return s;
	}

	override function destroy():Void
	{
		buttons = [];
		pressTimes = [];
		super.destroy();
	}
}

private typedef KeyBtn =
{
	var key:FlxKey;
	var circ:FlxSprite;
	var lbl:FlxText;
	var lit:Bool;
}
#end
