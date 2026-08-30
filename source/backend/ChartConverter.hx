package backend;

/**
 * ChartConverter - Pure algorithm chart conversion for Doubao Engine
 * 4K -> multi-K (5-9K) expansion and multi-K -> 4K compression
 * Designed to minimize overlapping notes
 */
class ChartConverter
{
	static final SIMULTANEOUS_WINDOW:Float = 80.0;
	static final STREAM_THRESHOLD:Float = 130.0;

	public static function convertChart(notesData:Array<Dynamic>, fromKeys:Int, toKeys:Int):Array<Dynamic>
	{
		if (fromKeys == toKeys) return notesData;
		if (toKeys > fromKeys) return expandChart(notesData, fromKeys, toKeys);
		return compressChart(notesData, fromKeys, toKeys);
	}

	public static function expandChart(notes:Array<Dynamic>, fromKeys:Int, toKeys:Int):Array<Dynamic>
	{
		var result:Array<Dynamic> = [];
		var extraLanes:Int = toKeys - fromKeys;
		if (extraLanes <= 0) return notes;

		var edgeMap:Map<Int, Int> = [];
		for (i in 0...fromKeys)
		{
			if (i < fromKeys / 2)
				edgeMap.set(i, i);
			else
				edgeMap.set(i, toKeys - (fromKeys - i));
		}

		var middleStart:Int = Math.ceil(fromKeys / 2);
		var middleEnd:Int = toKeys - Math.ceil(fromKeys / 2) - 1;
		var middleLanes:Array<Int> = [];
		for (i in middleStart...middleEnd + 1)
			if (i >= 0 && i < toKeys) middleLanes.push(i);

		var sorted:Array<Dynamic> = notes.copy();
		sorted.sort(function(a:Dynamic, b:Dynamic):Int {
			return Std.int(a.strumTime - b.strumTime);
		});

		var lastTime:Array<Float> = [];
		for (i in 0...fromKeys) lastTime.push(-9999);

		var middleIdx:Int = 0;

		for (note in sorted)
		{
			var origLane:Int = note.noteData;
			var newNote:Dynamic = Reflect.copy(note);
			var targetLane:Int = edgeMap.exists(origLane) ? edgeMap.get(origLane) : origLane;

			var timeGap:Float = note.strumTime - lastTime[origLane];
			if (timeGap < STREAM_THRESHOLD && timeGap > 0 && middleLanes.length > 0)
			{
				if (middleIdx % 3 == 1)
				{
					targetLane = middleLanes[middleIdx % middleLanes.length];
					middleIdx++;
				}
			}

			lastTime[origLane] = note.strumTime;
			newNote.noteData = targetLane;
			result.push(newNote);
		}

		result = resolveOverlaps(result, toKeys);
		return result;
	}

	public static function compressChart(notes:Array<Dynamic>, fromKeys:Int, toKeys:Int):Array<Dynamic>
	{
		var result:Array<Dynamic> = [];
		if (toKeys >= fromKeys) return notes;

		var sorted:Array<Dynamic> = notes.copy();
		sorted.sort(function(a:Dynamic, b:Dynamic):Int {
			return Std.int(a.strumTime - b.strumTime);
		});

		var groups:Array<Array<Dynamic>> = [];
		var currentGroup:Array<Dynamic> = [];
		var groupTime:Float = -1;

		for (note in sorted)
		{
			if (groupTime < 0 || Math.abs(note.strumTime - groupTime) <= SIMULTANEOUS_WINDOW)
			{
				currentGroup.push(note);
				if (groupTime < 0) groupTime = note.strumTime;
			}
			else
			{
				if (currentGroup.length > 0) groups.push(currentGroup);
				currentGroup = [note];
				groupTime = note.strumTime;
			}
		}
		if (currentGroup.length > 0) groups.push(currentGroup);

		for (group in groups)
		{
			group.sort(function(a:Dynamic, b:Dynamic):Int {
				return Std.int(a.noteData - b.noteData);
			});

			var groupSize:Int = group.length;

			if (groupSize <= toKeys)
			{
				for (i in 0...groupSize)
				{
					var newNote:Dynamic = Reflect.copy(group[i]);
					var lane:Int = Math.round(i * (toKeys - 1) / Math.max(1, groupSize - 1));
					newNote.noteData = lane;
					result.push(newNote);
				}
			}
			else
			{
				var mustPress:Array<Dynamic> = [];
				var autoPlay:Array<Dynamic> = [];
				for (note in group)
				{
					if (note.mustPress) mustPress.push(note);
					else autoPlay.push(note);
				}

				var usedLanes:Array<Bool> = [];
				for (i in 0...toKeys) usedLanes.push(false);

				var mpCount:Int = Std.int(Math.min(mustPress.length, toKeys));
				for (i in 0...mpCount)
				{
					var newNote:Dynamic = Reflect.copy(mustPress[i]);
					var lane:Int = findFreeLane(usedLanes, toKeys, i);
					newNote.noteData = lane;
					usedLanes[lane] = true;
					result.push(newNote);
				}

				for (i in mpCount...mustPress.length)
				{
					var newNote:Dynamic = Reflect.copy(mustPress[i]);
					newNote.noteData = i % toKeys;
					result.push(newNote);
				}

				for (note in autoPlay)
				{
					var lane:Int = findFreeLane(usedLanes, toKeys, -1);
					if (lane >= 0)
					{
						var newNote:Dynamic = Reflect.copy(note);
						newNote.noteData = lane;
						usedLanes[lane] = true;
						result.push(newNote);
					}
				}
			}
		}

		return result;
	}

	private static function resolveOverlaps(notes:Array<Dynamic>, keyCount:Int):Array<Dynamic>
	{
		var result:Array<Dynamic> = notes.copy();
		result.sort(function(a:Dynamic, b:Dynamic):Int {
			return Std.int(a.strumTime - b.strumTime);
		});

		var i:Int = 0;
		while (i < result.length)
		{
			var windowNotes:Array<Int> = [];
			var j:Int = i;
			while (j < result.length && Math.abs(result[j].strumTime - result[i].strumTime) <= SIMULTANEOUS_WINDOW)
			{
				windowNotes.push(j);
				j++;
			}

			if (windowNotes.length > 1)
			{
				var usedLanes:Array<Bool> = [];
				for (k in 0...keyCount) usedLanes.push(false);

				for (idx in windowNotes)
				{
					var lane:Int = result[idx].noteData;
					if (lane >= 0 && lane < keyCount)
					{
						if (usedLanes[lane])
						{
							var freeLane:Int = findFreeLane(usedLanes, keyCount, -1);
							if (freeLane >= 0)
							{
								result[idx].noteData = freeLane;
								usedLanes[freeLane] = true;
							}
						}
						else
						{
							usedLanes[lane] = true;
						}
					}
				}
			}

			i = j;
		}

		return result;
	}

	private static function findFreeLane(used:Array<Bool>, keyCount:Int, preferred:Int):Int
	{
		if (preferred >= 0 && preferred < keyCount && !used[preferred])
			return preferred;

		var center:Int = Math.floor(keyCount / 2);
		for (offset in 0...keyCount)
		{
			var left:Int = center - offset;
			var right:Int = center + offset;
			if (left >= 0 && !used[left]) return left;
			if (right < keyCount && !used[right]) return right;
		}
		return -1;
	}

	public static function detectKeyCount(notes:Array<Dynamic>):Int
	{
		var maxLane:Int = 0;
		for (note in notes)
		{
			if (note.noteData > maxLane) maxLane = note.noteData;
		}
		return maxLane + 1;
	}
}
