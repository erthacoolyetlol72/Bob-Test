package;

#if mobile
import flixel.FlxG;
import sys.io.Process;

using StringTools;

/**
 * Test helper used by the GitHub build: plays every song for a short while so crashes show up in the log.
 * It only does anything when the Android system property "debug.bob.smoketest" is set to 1,
 * which nobody does on a normal phone, so it is invisible in the real game.
 */
class SmokeTest
{
	static var songs:Array<String> = [
		'tutorial', 'sunshine', 'withered', 'run', 'ron', 'trouble', 'onslaught', 'little-man', 'run-remix-because-its-cool'
	];

	static var weeks:Array<Int> = [0, 1, 1, 1, 2, 2, 2, 2, 1];

	public static var active:Bool = false;

	static var timer:Float = 0;

	/** True when the test property is set. */
	public static function check():Bool
	{
		active = false;
		try
		{
			var p:Process = new Process("getprop", ["debug.bob.smoketest"]);
			var out:String = p.stdout.readAll().toString().trim();
			p.close();
			active = (out == "1");
		}
		catch (e:Dynamic) {}
		return active;
	}

	/** Starts the next song. The index is saved first, so after a crash the next launch moves on. */
	public static function startNext():Void
	{
		var i:Int = (FlxG.save.data.smokeIndex == null) ? 0 : FlxG.save.data.smokeIndex;
		if (i >= songs.length)
		{
			trace('SMOKE DONE');
			FlxG.save.data.smokeIndex = 0;
			FlxG.save.flush();
			active = false;
			return;
		}

		FlxG.save.data.smokeIndex = i + 1;
		FlxG.save.flush();

		var s:String = songs[i];
		timer = 0;
		trace('SMOKE START ' + i + ' ' + s);

		PlayState.SONG = Song.loadFromJson(Highscore.formatSong(s, 1), s);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = 1;
		PlayState.storyWeek = weeks[i];
		LoadingState.loadAndSwitchState(new PlayState());
	}

	/** Called every frame while a song is playing. Moves on after 25 seconds. */
	public static function update(elapsed:Float):Void
	{
		if (!active)
			return;

		timer += elapsed;
		if (timer > 25)
		{
			timer = 0;
			trace('SMOKE OK');
			startNext();
		}
	}
}
#end
