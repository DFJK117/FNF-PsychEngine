package backend;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.math.FlxMath;

/**
 * Doubao Engine global config.
 *
 * Two clearly separated modes:
 *   1) SOLO multi-key (4K..9K): a single centered row of receptors, DJMax-style
 *      symmetric physical binds. Two-player is force-disabled above 4K.
 *   2) TWO-PLAYER (4K only): left row = opponent Dad (Player 1, WASD),
 *      right row = boyfriend BF (Player 2, arrow keys).
 *
 * Lane direction/color tables mirror LeatherEngine's maniaDirections so the
 * arrows stay visually symmetric (e.g. 6K = L U R | L D R).
 */
class DoubaoConfig
{
	/** Maximum supported lanes (9K) */
	public static inline var MAX_KEYS:Int = 9;
	/** Vanilla 4K lane spacing baseline (160 * 0.7) */
	public static inline var BASE_SWAG_WIDTH:Float = 112;

	/** Lanes per side/row, synced from ClientPrefs.doubaoKeys */
	public static var keyCount:Int = 4;
	/** When true, keyCount is detected from the chart's raw note columns instead of the manual pref */
	public static var autoKeys:Bool = true;
	/** Raw two-player preference; only honored at 4K */
	public static var twoPlayer:Bool = false;

	/**
	 * Solo multi-key physical binds, indexed by lane count.
	 * 5K = D F SPACE G K (user specified); 6K/9K follow LeatherEngine symmetric layout.
	 */
	public static var SOLO_BINDS:Array<Array<FlxKey>> = [
		[],                                  // 0 (unused)
		[SPACE],                             // 1
		[F, J],                              // 2
		[F, SPACE, J],                       // 3
		[LEFT, DOWN, UP, RIGHT],            // 4 (vanilla arrows)
		[D, F, SPACE, G, K],                // 5
		[S, D, F, J, K, L],                 // 6
		[S, D, F, SPACE, J, K, L],          // 7
		[A, S, D, F, H, J, K, L],           // 8
		[A, S, D, F, SPACE, H, J, K, L]     // 9
	];

	/** Two-player 4K: Player 1 (opponent Dad, left); defaults A S W D, rebindable via ClientPrefs.keyBinds */
	public static var P1_KEYS:Array<FlxKey> = [A, S, W, D];
	/** Two-player 4K: Player 2 (boyfriend BF, right); defaults arrow keys, rebindable via ClientPrefs.keyBinds */
	public static var P2_KEYS:Array<FlxKey> = [LEFT, DOWN, UP, RIGHT];

	static function firstBind(name:String, fallback:FlxKey):FlxKey
	{
		var a:Array<FlxKey> = ClientPrefs.keyBinds.get(name);
		if (a != null && a.length > 0) return a[0];
		return fallback;
	}

	/** Reload P1/P2 physical keys from the rebindable keyBinds map */
	public static function refreshPlayerKeys():Void
	{
		P1_KEYS = [firstBind('doubao_p1_left', A), firstBind('doubao_p1_down', S), firstBind('doubao_p1_up', W), firstBind('doubao_p1_right', D)];
		P2_KEYS = [firstBind('doubao_p2_left', LEFT), firstBind('doubao_p2_down', DOWN), firstBind('doubao_p2_up', UP), firstBind('doubao_p2_right', RIGHT)];
	}

	/**
	 * Display direction per lane, indexed by lane count then lane index.
	 * 0 = LEFT(purple) 1 = DOWN(blue) 2 = UP(green) 3 = RIGHT(red).
	 * The center "SQUARE" lane of odd key counts reuses DOWN (no extra art needed).
	 */
	public static var DIRECTIONS:Array<Array<Int>> = [
		[],
		[1],                                  // 1
		[0, 3],                               // 2
		[0, 1, 3],                            // 3
		[0, 1, 2, 3],                         // 4  L D U R
		[0, 1, 1, 2, 3],                      // 5  L D (square) U R
		[0, 2, 3, 0, 1, 3],                   // 6  L U R | L D R
		[0, 2, 3, 1, 0, 1, 3],                // 7  L U R (square) L D R
		[0, 1, 2, 3, 0, 1, 2, 3],             // 8  L D U R | L D U R
		[0, 1, 2, 3, 1, 0, 1, 2, 3]           // 9  L D U R (square) L D U R
	];

	/** Sync settings from ClientPrefs, called once when a song starts */
	public static function syncFromPrefs():Void
	{
		autoKeys = ClientPrefs.data.doubaoKeysAuto;
		if (autoKeys)
		{
			// Keep whatever the chart scan already detected (applyDetectedKeyCount runs when the chart loads, before PlayState.create).
			// On a fresh launch with no chart loaded yet it stays at the static default of 4.
			if (keyCount < 4 || keyCount > MAX_KEYS) keyCount = 4;
		}
		else
		{
			keyCount = Std.int(FlxMath.bound(ClientPrefs.data.doubaoKeys, 4, MAX_KEYS));
		}
		// Two-player is only valid at 4K; any multi-key chart is strictly solo.
		twoPlayer = ClientPrefs.data.doubaoTwoPlayer && keyCount == 4;
		refreshPlayerKeys();
	}

	/**
	 * Scan a chart's RAW note columns (before Psych normalization) and infer its
	 * lane count. Charts encode the two ownership halves back-to-back, so a k-lane
	 * chart spans raw columns 0..(2k-1); e.g. vanilla 4K maxes at 7 -> k = 4.
	 * Only used when autoKeys is on. Returns the resulting (also stored) keyCount.
	 */
	public static function applyDetectedKeyCount(sectionsData:Dynamic):Int
	{
		if (!autoKeys) return keyCount;
		var maxRaw:Int = 3; // floor: vanilla chart always at least uses 0..3
		var sections:Array<Dynamic> = cast sectionsData;
		if (sections == null) return keyCount;
		for (section in sections)
		{
			if (section == null) continue;
			var noteList:Array<Dynamic> = cast section.sectionNotes;
			if (noteList == null) continue;
			for (sn in noteList)
			{
				var col:Dynamic = sn[1];
				// JSON numbers decode as Float; event notes may be arrays/strings and are skipped
				if (Std.isOfType(col, Float) || Std.isOfType(col, Int))
				{
					var c:Int = Std.int(col);
					if (c > maxRaw) maxRaw = c;
				}
			}
		}
		var detected:Int = Std.int(Math.ceil((maxRaw + 1) / 2));
		keyCount = Std.int(FlxMath.bound(detected, 4, MAX_KEYS));
		twoPlayer = ClientPrefs.data.doubaoTwoPlayer && keyCount == 4;
		return keyCount;
	}

	/** Whether two-player split layout is actually active */
	public static function isTwoPlayer():Bool
	{
		return twoPlayer && keyCount == 4;
	}

	/** Whether we are in a solo multi-key (>4K) mode */
	public static function isSoloMulti():Bool
	{
		return !isTwoPlayer() && keyCount > 4;
	}

	/** Display direction (0..3) for a lane in the current mode */
	public static function directionOf(lane:Int):Int
	{
		var row:Array<Int> = DIRECTIONS[keyCount];
		var idx:Int = lane;
		if (idx < 0) idx = -idx;
		if (row.length == 0) return idx % 4;
		return row[idx % row.length];
	}

	/**
	 * Lane spacing. Solo multi-key uses the FULL width for one centered row;
	 * two-player uses half width per side.
	 */
	public static function swagWidth():Float
	{
		var screenW:Float = (FlxG.width > 0 ? FlxG.width : 1280);
		if (isTwoPlayer())
		{
			var halfAvail:Float = screenW / 2 - 92;
			return Math.min(BASE_SWAG_WIDTH, halfAvail / keyCount);
		}
		// solo: one centered row, leave side padding
		var avail:Float = screenW - 160;
		return Math.min(BASE_SWAG_WIDTH, avail / keyCount);
	}

	/** Visual note scale vs vanilla (arrows shrink with spacing) */
	public static function noteScale():Float
	{
		return swagWidth() / BASE_SWAG_WIDTH;
	}

	/**
	 * X of the first receptor sprite for a row, chosen so the whole row is
	 * geometrically centered (lane i adds swagWidth*i on top).
	 * player = 0 -> opponent/Dad row, player = 1 -> BF row.
	 * Solo multi-key: single row horizontally centered (player ignored).
	 */
	public static function rowStartX(player:Int):Float
	{
		var sw:Float = swagWidth();
		var screenW:Float = (FlxG.width > 0 ? FlxG.width : 1280);
		var halfSpan:Float = sw * (keyCount - 1) / 2; // distance from row center to first receptor
		if (isTwoPlayer())
		{
			var halfW:Float = screenW / 2;
			var sideCenter:Float = player * halfW + halfW / 2; // 1/4 for Dad, 3/4 for BF
			return sideCenter - halfSpan;
		}
		return screenW / 2 - halfSpan; // solo centered
	}

	/** Physical key -> solo lane index (-1 if not a bind in current solo layout) */
	public static function getSoloIndex(k:FlxKey):Int
	{
		var binds:Array<FlxKey> = SOLO_BINDS[keyCount];
		for (i in 0...binds.length)
			if (binds[i] == k) return i;
		return -1;
	}

	/** Physical key -> Player 1 lane index (two-player 4K), -1 otherwise */
	public static function getP1Index(k:FlxKey):Int
	{
		if (!isTwoPlayer()) return -1;
		for (i in 0...P1_KEYS.length)
			if (P1_KEYS[i] == k) return i;
		return -1;
	}

	/** Physical key -> Player 2 lane index (two-player 4K), -1 otherwise */
	public static function getP2Index(k:FlxKey):Int
	{
		if (!isTwoPlayer()) return -1;
		for (i in 0...P2_KEYS.length)
			if (P2_KEYS[i] == k) return i;
		return -1;
	}

	/** Total chart columns including both ownership halves (player + opponent) */
	public static function totalColumns():Int
	{
		return keyCount * 2;
	}

	/**
	 * Raw chart column -> whether it must be hit manually.
	 * Two-player: both sides manual. Solo: only the player row (rawColumn < keyCount).
	 */
	public static function columnMustPress(rawColumn:Int):Bool
	{
		if (isTwoPlayer()) return true;
		return rawColumn >= 0 && rawColumn < keyCount;
	}
}
