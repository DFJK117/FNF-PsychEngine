package backend;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.math.FlxMath;

/**
 * Doubao Engine global config.
 * Centralizes: multi-key lane count, two-player keyboard mode,
 * lane layout calculation and P1/P2 physical key bindings.
 *
 * Conventions (aligned with vanilla Psych Engine):
 *   - player 0 = opponent Dad (left side), controlled by Player 1 in two-player mode
 *   - player 1 = boyfriend BF (right side), controlled by Player 2
 *   - raw chart noteData: 0 .. keyCount-1 = BF, keyCount .. 2*keyCount-1 = opponent
 */
class DoubaoConfig
{
	/** Maximum supported lanes per side (9K) */
	public static inline var MAX_KEYS:Int = 9;
	/** Vanilla 4K lane spacing, used as scaling baseline */
	public static inline var BASE_SWAG_WIDTH:Float = 160 * 0.7; // 112

	/** Current lanes per side (4/5/6/7/9), synced from ClientPrefs.doubaoKeys */
	public static var keyCount:Int = 4;
	/** Two-player keyboard mode switch, synced from ClientPrefs.doubaoTwoPlayer */
	public static var twoPlayer:Bool = false;

	/**
	 * Player 1 (opponent Dad, left side) physical keys, left to right, up to 9.
	 * 4K keeps classic WASD: left A / down S / up W / right D.
	 */
	public static var P1_KEYS:Array<FlxKey> = [
		A, S, W, D, F, G, H, J, K
	];

	/**
	 * Player 2 (boyfriend BF, right side) physical keys, left to right, up to 9.
	 * 4K keeps arrow keys, extra lanes use Z X C V B.
	 */
	public static var P2_KEYS:Array<FlxKey> = [
		LEFT, DOWN, UP, RIGHT, Z, X, C, V, B
	];

	/** Sync settings from ClientPrefs, called once when a song starts */
	public static function syncFromPrefs():Void
	{
		keyCount = Std.int(FlxMath.bound(ClientPrefs.data.doubaoKeys, 4, MAX_KEYS));
		twoPlayer = ClientPrefs.data.doubaoTwoPlayer;
	}

	/** Lanes per side */
	public static function keys():Int
	{
		return keyCount;
	}

	/** Total chart columns (opponent + player) */
	public static function totalColumns():Int
	{
		return keyCount * 2;
	}

	/**
	 * Lane spacing: shrinks as lane count grows so the whole row fits one half.
	 * 4K keeps vanilla 112, higher counts narrow automatically.
	 */
	public static function swagWidth():Float
	{
		var halfWidth:Float = (FlxG.width > 0 ? FlxG.width : 1280) / 2;
		var available:Float = halfWidth - 92; // side padding
		var fitted:Float = available / keyCount;
		return Math.min(BASE_SWAG_WIDTH, fitted);
	}

	/** Visual note scale vs vanilla (arrows shrink with spacing to avoid crowding) */
	public static function noteScale():Float
	{
		return swagWidth() / BASE_SWAG_WIDTH;
	}

	/** Physical key -> Player 1 lane index (-1 if not a P1 key) */
	public static function getP1Index(k:FlxKey):Int
	{
		var n:Int = (keyCount < P1_KEYS.length) ? keyCount : P1_KEYS.length;
		for (i in 0...n)
			if (P1_KEYS[i] == k) return i;
		return -1;
	}

	/** Physical key -> Player 2 lane index (-1 if not a P2 key) */
	public static function getP2Index(k:FlxKey):Int
	{
		var n:Int = (keyCount < P2_KEYS.length) ? keyCount : P2_KEYS.length;
		for (i in 0...n)
			if (P2_KEYS[i] == k) return i;
		return -1;
	}

	/**
	 * Raw chart column -> whether it must be hit manually.
	 * Normal: only BF side (rawColumn < keyCount); two-player: both sides.
	 */
	public static function columnMustPress(rawColumn:Int):Bool
	{
		if (twoPlayer) return true;
		return rawColumn < keyCount;
	}
}
