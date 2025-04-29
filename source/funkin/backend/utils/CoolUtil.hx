package funkin.backend.utils;

#if sys
import sys.FileSystem;
#end
import flixel.text.FlxText;
import funkin.backend.utils.XMLUtil.TextFormat;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.typeLimit.OneOfThree;
import flixel.tweens.FlxTween;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.sound.FlxSound;
import funkin.backend.system.Conductor;
import flixel.sound.FlxSoundGroup;
import haxe.Json;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.xml.Access;
import flixel.input.keyboard.FlxKey;
import lime.utils.Assets;
import flixel.animation.FlxAnimation;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import openfl.geom.ColorTransform;
import haxe.CallStack;

using StringTools;

@:allow(funkin.game.PlayState)
#if cpp
@:cppFileCode('#include <thread>')
#end
class CoolUtil {
    public static function getLastExceptionStack():String {
        return CallStack.toString(CallStack.exceptionStack());
    }

    /*
     * Returns `v` if not null
     * @param v The value
     * @return A bool value
     */
    public static inline function isNotNull(v:Null<Dynamic>):Bool {
        return v != null && !isNaN(v);
    }

    /*
     * Returns `v` if not null, `defaultValue` otherwise.
     * @param v The value
     * @param defaultValue The default value
     * @return The return value
     */
    public static inline function getDefault<T>(v:Null<T>, defaultValue:T):T {
        return (v == null || isNaN(v)) ? defaultValue : v;
    }

    /**
     * Shortcut to parse JSON from an Asset path
     * @param assetPath Path to the JSON asset.
     */
    public static function parseJson(assetPath:String) {
        return Json.parse(Assets.getText(assetPath));
    }

    /**
     * Deletes a folder recursively (adjusted to work only with internal assets)
     * @param delete Path to the folder.
     */
    @:noUsing public static function deleteFolder(delete:String) {
        #if sys
        trace("Deleting folders is not supported for internal assets.");
        #end
    }

    /**
     * Safe saves a file (adjusted to avoid external storage)
     * @param path Path to save the file at.
     * @param content Content of the file to save (as String or Bytes).
     */
    @:noUsing public static function safeSaveFile(path:String, content:OneOfTwo<String, Bytes>, showErrorBox:Bool = true) {
        trace("Saving files is not supported for internal assets.");
    }

    /**
     * Creates eventual missing folders to the specified `path` (adjusted to avoid external storage)
     * @param path Path to check.
     * @return The initial Path.
     */
    @:noUsing public static function addMissingFolders(path:String):String {
        trace("Creating folders is not supported for internal assets.");
        return path;
    }

    /**
     * Shortcut to parse a JSON string
     * @param str Path to the JSON string
     * @return Parsed JSON
     */
    public inline static function parseJsonString(str:String)
        return Json.parse(str);

    /**
     * Plays the main menu theme.
     * @param fadeIn
     */
    @:noUsing public static function playMenuSong(fadeIn:Bool = false) {
        if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
            playMusic(Paths.music("assets/music/freakyMenu"), true, fadeIn ? 0 : 1, true, 102);
            FlxG.sound.music.persist = true;
            if (fadeIn)
                FlxG.sound.music.fadeIn(4, 0, 0.7);
        }
    }

    /**
     * Preloads a character.
     * @param name Character name
     * @param spriteName (Optional) sprite name.
     */
    @:noUsing public static function preloadCharacter(name:String, ?spriteName:String) {
        if (name == null) return;
        if (spriteName == null)
            spriteName = name;
        Assets.getText(Paths.xml('characters/$name'));
        Paths.getFrames('characters/$spriteName');
    }

    /**
     * Plays music, while resetting the Conductor, and taking info from INI in count.
     * @param path Path to the music
     * @param Persist Whenever the music should persist while switching states
     * @param DefaultBPM Default BPM of the music (102)
     * @param Volume Volume of the music (1)
     * @param Looped Whenever the music loops (true)
     * @param Group A group that this music belongs to (default)
     */
    @:noUsing public static function playMusic(path:String, Persist:Bool = false, Volume:Int = 1, Looped:Bool = true, DefaultBPM:Int = 102, ?Group:FlxSoundGroup) {
        Conductor.reset();
        FlxG.sound.playMusic(path, Volume, Looped, Group);
        if (FlxG.sound.music != null) {
            FlxG.sound.music.persist = Persist;
        }

        var infoPath = '${Path.withoutExtension(path)}.ini';
        if (Assets.exists(infoPath)) {
            var musicInfo = IniUtil.parseAsset(infoPath, [
                "BPM" => null,
                "TimeSignature" => "4/4"
            ]);

            var timeSignParsed:Array<Null<Float>> = musicInfo["TimeSignature"] == null ? [] : [for(s in musicInfo["TimeSignature"].split("/")) Std.parseFloat(s)];
            var beatsPerMeasure:Float = 4;
            var stepsPerBeat:Float = 4;

            if (timeSignParsed.length == 2 && !timeSignParsed.contains(null)) {
                beatsPerMeasure = timeSignParsed[0] == null || timeSignParsed[0] <= 0 ? 4 : cast timeSignParsed[0];
                stepsPerBeat = timeSignParsed[1] == null || timeSignParsed[1] <= 0 ? 4 : cast timeSignParsed[1];
            }

            var bpm:Null<Float> = Std.parseFloat(musicInfo["BPM"]).getDefault(DefaultBPM);
            Conductor.changeBPM(bpm, beatsPerMeasure, stepsPerBeat);
        } else
            Conductor.changeBPM(DefaultBPM);
    }

    /**
     * Opens an URL in the browser.
     * @param url
     */
    @:noUsing public static inline function openURL(url:String) {
        FlxG.openURL(url);
    }

    /**
     * Converts a timestamp to a readable format such as `01:22` (`mm:ss`)
     */
    public static inline function timeToStr(time:Float)
        return '${Std.string(Std.int(time / 60000)).addZeros(2)}:${Std.string(Std.int(time / 1000) % 60).addZeros(2)}.${Std.string(Std.int(time % 1000)).addZeros(3)}';

    /**
     * Stops a sound, set its time to 0 then play it again.
     * @param sound Sound to replay.
     */
    public static inline function replay(sound:FlxSound) {
        sound.stop();
        sound.time = 0;
        sound.play();
    }

    /**
     * Clears the content of an array
     */
    public static inline function clear<T>(array:Array<T>):Array<T> {
        array.resize(0);
        return array;
    }
}
