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
	/** Maximum supported lanes (up to a 61-key piano-style layout) */
	public static inline var MAX_KEYS:Int = 61;
	/** Vanilla 4K lane spacing baseline (160 * 0.7) */
	public static inline var BASE_SWAG_WIDTH:Float = 112;

	/** Lanes per side/row, synced from ClientPrefs.doubaoKeys */
	public static var keyCount:Int = 4;
	/** When true, keyCount is detected from the chart's raw note columns instead of the manual pref */
	public static var autoKeys:Bool = true;
	/** Raw two-player preference; only honored at 4K */
	public static var twoPlayer:Bool = false;

	/**
	 * Hand-tuned binds for the common 1..9K counts (stable muscle memory).
	 * 5K = D F SPACE J K (piano: left hand D F, thumb SPACE, right hand J K).
	 */
	public static var SOLO_BINDS:Array<Array<FlxKey>> = [
		[],                                  // 0 (unused)
		[SPACE],                             // 1
		[F, J],                              // 2
		[F, SPACE, J],                       // 3
		[LEFT, DOWN, UP, RIGHT],             // 4 (vanilla arrows)
		[D, F, SPACE, J, K],                 // 5
		[S, D, F, J, K, L],                  // 6
		[S, D, F, SPACE, J, K, L],           // 7
		[A, S, D, F, H, J, K, L],            // 8
		[A, S, D, F, SPACE, H, J, K, L]      // 9
	];

	// Hand-feel pick order (near axis -> far) for the first 4 symmetric pairs.
	static var L_STACK:Array<FlxKey> = [F, D, S, A];
	static var R_STACK:Array<FlxKey> = [J, K, L, H];
	// Strictly mirroring pairs (left,right) used from the 5th pair outward, for 10K+.
	static var EXTRA_PAIRS:Array<Array<FlxKey>> = [
		[R, U], [E, I], [W, O], [Q, P], [T, Y],
		[V, M], [C, COMMA], [X, PERIOD], [Z, SLASH], [B, N],
		[G, SEMICOLON],
		[FIVE, SIX], [FOUR, SEVEN], [THREE, EIGHT], [TWO, NINE], [ONE, ZERO], [GRAVEACCENT, MINUS],
		[LEFT, RIGHT], [DOWN, UP]
	];
	// Appended at the far right for the extreme 50K..61K range (numeric pad).
	static var TAIL_KEYS:Array<FlxKey> = [NUMPADZERO, NUMPADONE, NUMPADTWO, NUMPADTHREE, NUMPADFOUR, NUMPADFIVE, NUMPADSIX, NUMPADSEVEN, NUMPADEIGHT, NUMPADNINE, NUMPADPERIOD, NUMPADPLUS, NUMPADMINUS, NUMPADMULTIPLY];

	/** Physical left->right weight so the picked keys are emitted in keyboard order. */
	static var XRANK:Map<FlxKey, Float> = null;
	static function buildXRank():Void
	{
		XRANK = new Map();
		var numRow:Array<FlxKey> = [GRAVEACCENT, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, ZERO, MINUS];
		for (i => k in numRow) XRANK.set(k, 100 + i);
		var qRow:Array<FlxKey> = [Q, W, E, R, T, Y, U, I, O, P, LBRACKET, RBRACKET];
		for (i => k in qRow) XRANK.set(k, 200 + i);
		var aRow:Array<FlxKey> = [A, S, D, F, G, H, J, K, L, SEMICOLON, QUOTE];
		for (i => k in aRow) XRANK.set(k, 300 + i);
		XRANK.set(SPACE, 304.5); // between F and H (thumb)
		var zRow:Array<FlxKey> = [Z, X, C, V, B, N, M, COMMA, PERIOD, SLASH];
		for (i => k in zRow) XRANK.set(k, 400 + i);
		XRANK.set(LEFT, 500); XRANK.set(DOWN, 501); XRANK.set(UP, 502); XRANK.set(RIGHT, 503);
		for (i => k in TAIL_KEYS) XRANK.set(k, 600 + i);
	}
	static function xrankOf(k:FlxKey):Float
	{
		if (XRANK == null) buildXRank();
		if (XRANK.exists(k)) return XRANK.get(k);
		var ki:Int = k; // enum abstract over Int -> safe unbox
		return 900 + ki;
	}

	/**
	 * Build physical binds for ANY lane count 1..MAX_KEYS.
	 * Expands symmetrically outward from F/J; odd counts insert SPACE in the middle,
	 * then everything is sorted into physical left->right keyboard order.
	 */
	public static function buildSoloBinds(k:Int):Array<FlxKey>
	{
		if (k >= 0 && k < SOLO_BINDS.length && SOLO_BINDS[k].length == k) return SOLO_BINDS[k].copy();
		var odd:Bool = (k % 2 == 1);
		var pairs:Int = odd ? ((k - 1) >> 1) : (k >> 1);
		var sel:Array<FlxKey> = [];
		for (i in 0...pairs)
		{
			if (i < L_STACK.length) { sel.push(L_STACK[i]); sel.push(R_STACK[i]); }
			else
			{
				var ei:Int = i - L_STACK.length;
				if (ei < EXTRA_PAIRS.length) { sel.push(EXTRA_PAIRS[ei][0]); sel.push(EXTRA_PAIRS[ei][1]); }
			}
		}
		if (odd) sel.push(SPACE);
		var ti:Int = 0;
		while (sel.length < k && ti < TAIL_KEYS.length) { sel.push(TAIL_KEYS[ti]); ti++; }
		sel.sort(function(a, b):Int {
			var xa:Float = xrankOf(a), xb:Float = xrankOf(b);
			return xa < xb ? -1 : (xa > xb ? 1 : 0);
		});
		return sel;
	}

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
			if (keyCount < 1 || keyCount > MAX_KEYS) keyCount = 4;
		}
		else
		{
			// manual override allows the full 1K..61K range
			keyCount = Std.int(FlxMath.bound(ClientPrefs.data.doubaoKeys, 1, MAX_KEYS));
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

	/** Whether we are in a solo custom-key layout (anything other than vanilla 4K: 1K..3K or 5K..61K) */
	public static function isSoloMulti():Bool
	{
		return !isTwoPlayer() && keyCount != 4;
	}

	/** Display direction (0..3) for a lane in the current mode */
	public static function directionOf(lane:Int):Int
	{
		var idx:Int = lane < 0 ? -lane : lane;
		if (keyCount >= 0 && keyCount < DIRECTIONS.length)
		{
			var row:Array<Int> = DIRECTIONS[keyCount];
			if (row.length > 0) return row[idx % row.length];
		}
		// 10K+: cycle LEFT/DOWN/UP/RIGHT so colors spread evenly across the row
		return idx % 4;
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
		// solo: one centered row. Tighten side padding as lane count grows so dense
		// layouts (10K..61K) still fill the width and each arrow stays as large as possible.
		var pad:Float = keyCount > 20 ? 16 : (keyCount > 9 ? 48 : 160);
		var avail:Float = screenW - pad;
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
		var binds:Array<FlxKey> = buildSoloBinds(keyCount);
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
