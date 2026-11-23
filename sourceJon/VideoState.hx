package;

import flixel.FlxState;
import flixel.FlxG;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import flixel.system.FlxSound;
import openfl.utils.Assets;
import openfl.utils.AssetType;

import openfl.Lib;

using StringTools;

class VideoState extends MusicBeatState
{
	public var leSource:String = "";
	public var transClass:FlxState;
	public var txt:FlxText;
	public var fuckingVolume:Float = 1;
	public var notDone:Bool = true;
	public var vidSound:FlxSound;
	public var useSound:Bool = false;
	public var soundMultiplier:Float = 1;
	public var prevSoundMultiplier:Float = 1;
	public var videoFrames:Int = 0;
	public var defaultText:String = "";
	public var doShit:Bool = false;
	public var pauseText:String = "Press P To Pause/Unpause";

	public function new(source:String, toTrans:FlxState)
	{
		super();
		
		leSource = source;
		transClass = toTrans;
	}
	
	#if mobile
	/**
	 * Phones have no video player. The build turns each video into pictures
	 * (assets/videoframes/NAME/f0001.jpg, f0002.jpg ...) and this plays them in step with the sound track.
	 */
	var frameSprite:FlxSprite;
	var lastFrame:Int = -1;
	var mobileTime:Float = 0;
	var mobileEnded:Bool = false;
	var frameFolder:String = "";

	function createMobile():Void
	{
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		frameSprite = new FlxSprite();
		add(frameSprite);

		// "assets/videos/ronPreCutscene/ronPreCutscene.webm" -> "ronPreCutscene"
		var name:String = leSource.substring(leSource.lastIndexOf("/") + 1, leSource.lastIndexOf("."));
		frameFolder = "assets/videoframes/" + name + "/";

		var countFile:String = leSource.replace(".webm", ".txt");
		var counted:Null<Int> = Assets.exists(countFile) ? Std.parseInt(Assets.getText(countFile)) : null;
		videoFrames = (counted == null || counted <= 0) ? 240 : counted;

		fuckingVolume = (FlxG.sound.music != null) ? FlxG.sound.music.volume : 1;
		if (FlxG.sound.music != null)
			FlxG.sound.music.volume = 0;

		var ogg:String = leSource.replace(".webm", ".ogg");
		if (Assets.exists(ogg, MUSIC) || Assets.exists(ogg, SOUND))
		{
			useSound = true;
			vidSound = FlxG.sound.play(ogg);
		}

		trace('VIDEO start ' + frameFolder + ' frames=' + videoFrames + ' sound=' + useSound + (useSound ? (' length=' + vidSound.length) : ''));
		showFrame(0);
	}

	function showFrame(i:Int):Void
	{
		// ffmpeg numbers the pictures from 1
		var key:String = frameFolder + "f" + StringTools.lpad(Std.string(i + 1), "0", 4) + ".jpg";
		if (!Assets.exists(key))
		{
			trace('VIDEO missing picture ' + key);
			return;
		}

		// not cached: 300+ pictures would otherwise pile up in memory
		var bmp = Assets.getBitmapData(key, false);
		if (bmp == null)
			return;

		frameSprite.loadGraphic(bmp);
		frameSprite.setGraphicSize(FlxG.width, FlxG.height);
		frameSprite.updateHitbox();
		frameSprite.screenCenter();
		lastFrame = i;
	}

	function finishMobile():Void
	{
		if (mobileEnded)
			return;

		mobileEnded = true;
		trace('VIDEO end after ' + mobileTime + 's, last picture ' + lastFrame);
		if (vidSound != null)
			vidSound.stop();
		if (FlxG.sound.music != null)
			FlxG.sound.music.volume = fuckingVolume;
		FlxG.autoPause = true;
		FlxG.switchState(transClass);
	}

	function updateMobile(elapsed:Float):Void
	{
		if (mobileEnded)
			return;

		mobileTime += elapsed;

		// pictures per second: spread them over the sound track's length, or 24 per second without sound
		var fps:Float = 24;
		if (useSound && vidSound != null && vidSound.length > 0)
			fps = videoFrames / (vidSound.length / 1000);

		var frame:Int = Std.int(mobileTime * fps);
		if (frame >= videoFrames)
		{
			finishMobile();
			return;
		}
		if (frame != lastFrame)
			showFrame(frame);

		// a tap or the accept button skips the video
		var tapped:Bool = false;
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				tapped = true;
		}
		if (tapped || controls.ACCEPT)
			finishMobile();
	}
	#end

	override function create()
	{
		super.create();

		#if mobile
		// phones have no video player (GlobalVideo is never set up there): show the cutscene as pictures
		createMobile();
		return;
		#end

		FlxG.autoPause = false;
		doShit = false;
		
		if (GlobalVideo.isWebm)
		{
		videoFrames = Std.parseInt(Assets.getText(leSource.replace(".webm", ".txt")));
		}
		
		fuckingVolume = FlxG.sound.music.volume;
		FlxG.sound.music.volume = 0;
		var isHTML:Bool = false;
		#if web
		isHTML = true;
		#end
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		txt = new FlxText(0, 0, FlxG.width,
			defaultText,
			32);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);

		if (GlobalVideo.isWebm)
		{
			if (Assets.exists(leSource.replace(".webm", ".ogg"), MUSIC) || Assets.exists(leSource.replace(".webm", ".ogg"), SOUND))
			{
				useSound = true;
				vidSound = FlxG.sound.play(leSource.replace(".webm", ".ogg"));
			}
		}

		GlobalVideo.get().source(leSource);
		GlobalVideo.get().clearPause();
		if (GlobalVideo.isWebm)
		{
			GlobalVideo.get().updatePlayer();
		}
		GlobalVideo.get().show();
		if (GlobalVideo.isWebm)
		{
			GlobalVideo.get().restart();
		} else {
			GlobalVideo.get().play();
		}
		
		/*if (useSound)
		{*/
			//vidSound = FlxG.sound.play(leSource.replace(".webm", ".ogg"));
		
			/*new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{*/
				vidSound.time = vidSound.length * soundMultiplier;
				/*new FlxTimer().start(1.2, function(tmr:FlxTimer)
				{
					if (useSound)
					{
						vidSound.time = vidSound.length * soundMultiplier;
					}
				}, 0);*/
				doShit = true;
			//}, 1);
		//}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		#if mobile
		updateMobile(elapsed);
		return;
		#end
		
		if (useSound)
		{
			var wasFuckingHit = GlobalVideo.get().webm.wasHitOnce;
			soundMultiplier = GlobalVideo.get().webm.renderedCount / videoFrames;
			
			if (soundMultiplier > 1)
			{
				soundMultiplier = 1;
			}
			if (soundMultiplier < 0)
			{
				soundMultiplier = 0;
			}
			if (doShit)
			{
				var compareShit:Float = 50;
				if (vidSound.time >= (vidSound.length * soundMultiplier) + compareShit || vidSound.time <= (vidSound.length * soundMultiplier) - compareShit)
					vidSound.time = vidSound.length * soundMultiplier;
			}
			if (wasFuckingHit)
			{
			if (soundMultiplier == 0)
			{
				if (prevSoundMultiplier != 0)
				{
					vidSound.pause();
					vidSound.time = 0;
				}
			} else {
				if (prevSoundMultiplier == 0)
				{
					vidSound.resume();
					vidSound.time = vidSound.length * soundMultiplier;
				}
			}
			prevSoundMultiplier = soundMultiplier;
			}
		}
		
		if (notDone)
		{
			FlxG.sound.music.volume = 0;
		}
		GlobalVideo.get().update(elapsed);

		if (controls.RESET)
		{
			GlobalVideo.get().restart();
		}
		
		if (FlxG.keys.justPressed.P)
		{
			txt.text = pauseText;
			trace("PRESSED PAUSE");
			GlobalVideo.get().togglePause();
			if (GlobalVideo.get().paused)
			{
				GlobalVideo.get().alpha();
			} else {
				GlobalVideo.get().unalpha();
				txt.text = defaultText;
			}
		}
		
		if (controls.ACCEPT || GlobalVideo.get().ended || GlobalVideo.get().stopped)
		{
			txt.visible = false;
			GlobalVideo.get().hide();
			GlobalVideo.get().stop();
		}
		
		if (controls.ACCEPT || GlobalVideo.get().ended)
		{
			notDone = false;
			FlxG.sound.music.volume = fuckingVolume;
			txt.text = pauseText;
			FlxG.autoPause = true;
			FlxG.switchState(transClass);
		}
		
		if (GlobalVideo.get().played || GlobalVideo.get().restarted)
		{
			GlobalVideo.get().show();
		}
		
		GlobalVideo.get().restarted = false;
		GlobalVideo.get().played = false;
		GlobalVideo.get().stopped = false;
		GlobalVideo.get().ended = false;
	}
}