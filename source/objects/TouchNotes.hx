package objects;

// ============================================================================
// Doubao Engine - mobile multi-touch note layer (Android / iOS)
//
// Every finger is tracked independently by its touch id, so pressing three
// (or more) lanes at the same time never drops a note, and lifting one finger
// never releases the lanes held by the other fingers (Hitbox-style).
//
// Visual style is inspired by NFE: a circle per lane that lights up and grows
// slightly while pressed, and dims back down (letter stays visible) on release.
// A CPS + total-press counter is drawn in the corner.
//
// This whole file is compiled ONLY on mobile targets, the desktop build is
// completely untouched.
// ============================================================================
#if mobile
import backend.DoubaoConfig;
import openfl.display.BitmapData;
import openfl.display.Shape;

class TouchNotes extends FlxTypedGroup<FlxSprite>
{
	// 0 = LEFT (purple), 1 = DOWN (blue), 2 = UP (green), 3 = RIGHT (red)
	static final DIR_COLOR:Array<Int> = [0xD949D9, 0x3A78E8, 0x37D64B, 0xE84848];
	static final DIR_LETTER:Array<String> = ['L', 'D', 'U', 'R'];
	static final SLOT_STRIDE:Int = 96; // global index = side * STRIDE + lane

	// Callbacks routed straight into PlayState.keyPressed / keyReleased (lane index)
	var onPress:Int->Void;
	var onRelease:Int->Void;
	var onPressP1:Int->Void;
	var onReleaseP1:Int->Void;
	var onPause:Void->Void;

	// Thin top strip that acts as the pause button (kept away from the play area)
	static final PAUSE_BAND:Float = 48;
	var topTouches:Map<Int,{x:Float,y:Float}> = new Map();

	// Parallel button descriptors (one entry per visible circle)
	var gIndex:Array<Int> = [];
	var gSide:Array<Int> = [];
	var gLane:Array<Int> = [];
	var gCenterX:Array<Float> = [];
	var halfWidth:Float = 40;

	var circles:Map<Int, FlxSprite> = new Map();
	var labels:Map<Int, FlxText> = new Map();
	var heldCount:Map<Int, Int> = new Map();

	// touch id -> (side, lane)
	var held:Map<Int, TouchSlot> = new Map();

	var timeNow:Float = 0;
	var pressTimes:Array<Float> = [];
	public var totalPress:Int = 0;
	var stat:FlxText = null;

	public function new(press:Int->Void, release:Int->Void, pressP1:Int->Void, releaseP1:Int->Void, pauseCb:Void->Void)
	{
		super();
		onPress = press;
		onRelease = release;
		onPressP1 = pressP1;
		onReleaseP1 = releaseP1;
		onPause = pauseCb;
		build();
	}

	function build():Void
	{
		final lanes:Int = DoubaoConfig.keyCount;
		final twoP:Bool = DoubaoConfig.isTwoPlayer();
		final sw:Float = DoubaoConfig.swagWidth();
		halfWidth = sw * 0.55; // generous hit zone so a thumb never misses horizontally

		// Player 2 (BF) uses downScroll; Player 1 has its own direction in two-player
		final down:Bool = ClientPrefs.data.downScroll;
		final diameter:Float = Math.max(34, sw * 0.92);
		final radius:Float = diameter / 2;

		final sides:Int = twoP ? 2 : 1;
		for (side in 0...sides)
		{
			// Solo play is always the BF/player side (1); two-player uses 0 (Dad) and 1 (BF)
			final realSide:Int = twoP ? side : 1;
			final startX:Float = twoP ? DoubaoConfig.rowStartX(side) : DoubaoConfig.rowStartX(1);
			final sideDown:Bool = twoP ? (realSide == 0 ? ClientPrefs.data.doubaoP1DownScroll : down) : down;
			final yPos:Float = sideDown ? (FlxG.height - radius - 12) : (radius + 64);

			for (lane in 0...lanes)
			{
				final gi:Int = realSide * SLOT_STRIDE + lane;
				final cx:Float = startX + sw * lane;
				final dir:Int = DoubaoConfig.directionOf(lane);

				final circ:FlxSprite = makeCircle(Std.int(diameter), DIR_COLOR[dir]);
				circ.x = cx;
				circ.y = yPos;
				circ.alpha = 0.28; // dim at rest
				add(circ);
				circles[gi] = circ;

				final fontSize:Int = Std.int(Math.max(13, diameter * 0.42));
				final lbl:FlxText = new FlxText(cx - radius, yPos - radius, diameter, DIR_LETTER[dir], fontSize);
				lbl.setFormat(Paths.font('vcr.ttf'), fontSize, FlxColor.WHITE, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				lbl.scrollFactor.set();
				lbl.centerOrigin();
				lbl.x = cx;
				lbl.y = yPos;
				add(lbl);
				labels[gi] = lbl;

				gIndex.push(gi);
				gSide.push(realSide);
				gLane.push(lane);
				gCenterX.push(cx);
				heldCount[gi] = 0;
			}
		}

		stat = new FlxText(8, FlxG.height - 34, 360, '', 18);
		stat.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, flixel.text.FlxTextAlign.LEFT, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		stat.scrollFactor.set();
		add(stat);

		// tiny hint that the very top strip pauses the song
		final pauseHint:FlxText = new FlxText(0, 6, FlxG.width, 'TAP TOP TO PAUSE', 14);
		pauseHint.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pauseHint.scrollFactor.set();
		pauseHint.alpha = 0.5;
		add(pauseHint);

		updateStat(true);
	}

	public function setCameras(cams:Array<FlxCamera>):Void
	{
		for (s in members)
		{
			if (s != null) s.cameras = cams;
		}
	}

	function makeCircle(size:Int, color:Int):FlxSprite
	{
		final bmp:BitmapData = new BitmapData(size, size, true, 0x00000000);
		final shape:Shape = new Shape();
		shape.graphics.lineStyle(Math.max(2, Std.int(size * 0.06)), FlxColor.WHITE, 0.85);
		shape.graphics.beginFill(color, 1.0);
		shape.graphics.drawCircle(size / 2, size / 2, size / 2 - 2);
		shape.graphics.endFill();
		bmp.draw(shape);
		final spr:FlxSprite = new FlxSprite();
		spr.pixels = bmp;
		spr.frameWidth = size;
		spr.frameHeight = size;
		spr.centerOrigin();
		spr.scrollFactor.set();
		spr.antialiasing = true;
		return spr;
	}

	function hitTest(x:Float):TouchSlot
	{
		var best:Int = -1;
		var bestDist:Float = Math.POSITIVE_INFINITY;
		for (i in 0...gIndex.length)
		{
			final d:Float = Math.abs(x - gCenterX[i]);
			if (d < halfWidth && d < bestDist)
			{
				bestDist = d;
				best = i;
			}
		}
		if (best < 0) return null;
		return {side: gSide[best], lane: gLane[best]};
	}

	public function tick(elapsed:Float):Void
	{
		timeNow += elapsed;
		while (pressTimes.length > 0 && pressTimes[0] < timeNow - 1.0)
			pressTimes.shift();

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				// top strip = pause, never a note
				if (touch.y < PAUSE_BAND)
				{
					topTouches[touch.touchPointID] = {x: touch.x, y: touch.y};
					continue;
				}
				final slot:TouchSlot = hitTest(touch.x);
				if (slot != null && !held.exists(touch.touchPointID))
				{
					held[touch.touchPointID] = slot;
					final gi:Int = slot.side * SLOT_STRIDE + slot.lane;
					final before:Int = (heldCount[gi] == null) ? 0 : heldCount[gi];
					heldCount[gi] = before + 1;
					if (before == 0)
					{
						light(gi, true);
						if (slot.side == 1) onPress(slot.lane); else onPressP1(slot.lane);
						totalPress++;
						pressTimes.push(timeNow);
					}
				}
			}
			else if (touch.justReleased)
			{
				if (topTouches.exists(touch.touchPointID))
				{
					final s:{x:Float,y:Float} = topTouches[touch.touchPointID];
					topTouches.remove(touch.touchPointID);
					if (touch.y < PAUSE_BAND + 24 && Math.abs(touch.x - s.x) < 24 && Math.abs(touch.y - s.y) < 24)
						onPause();
					continue;
				}
				if (held.exists(touch.touchPointID))
				{
					final slot:TouchSlot = held[touch.touchPointID];
					held.remove(touch.touchPointID);
					final gi:Int = slot.side * SLOT_STRIDE + slot.lane;
					var cur:Int = (heldCount[gi] == null) ? 0 : heldCount[gi];
					if (cur > 0) cur--;
					heldCount[gi] = cur;
					if (cur == 0)
					{
						light(gi, false);
						if (slot.side == 1) onRelease(slot.lane); else onReleaseP1(slot.lane);
					}
				}
			}
		}

		updateStat(false);
	}

	function light(gi:Int, on:Bool):Void
	{
		final circ:FlxSprite = circles[gi];
		if (circ == null) return;
		if (on)
		{
			circ.alpha = 1.0;
			circ.scale.set(1.12, 1.12); // press "pop"
		}
		else
		{
			circ.alpha = 0.28;
			circ.scale.set(1, 1);
		}
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

	override function destroy():Void
	{
		held.clear();
		topTouches.clear();
		circles.clear();
		labels.clear();
		heldCount.clear();
		pressTimes = [];
		super.destroy();
	}
}

private typedef TouchSlot =
{
	var side:Int; // 0 = P1/Dad, 1 = P2/BF
	var lane:Int;
}
#end
