/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.funkin.backend.system;

#if mobile
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets as OpenFLAssets;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import openfl.utils.ByteArray;
import haxe.io.Path;
import funkin.backend.utils.NativeAPI;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;
import lime.system.ThreadPool;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

/**
 * @author: Karim Akra
 * Handles copying and verifying assets for the game.
 */
class CopyState extends funkin.backend.MusicBeatState {
    private static final textFilesExtensions:Array<String> = ['ini', 'txt', 'xml', 'hxs', 'hx', 'lua', 'json', 'frag', 'vert'];
    public static final IGNORE_FOLDER_FILE_NAME:String = "CopyState-Ignore.txt";
    private static var directoriesToIgnore:Array<String> = [];
    public static var locatedFiles:Array<String> = [];
    public static var maxLoopTimes:Int = 0;

    public var loadingImage:FlxSprite;
    public var loadingBar:FlxBar;
    public var loadedText:FlxText;
    public var thread:ThreadPool;

    var failedFilesStack:Array<String> = [];
    var failedFiles:Array<String> = [];
    var shouldCopy:Bool = false;
    var canUpdate:Bool = true;
    var loopTimes:Int = 0;

    override function create() {
        locatedFiles = [];
        maxLoopTimes = 0;
        checkExistingFiles();
        if (maxLoopTimes <= 0) {
            FlxG.resetGame();
            return;
        }

        NativeAPI.showMessageBox("Notice", "Some files are missing. Verifying assets inside the APK...");

        shouldCopy = true;

        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d));

        loadingImage = new FlxSprite(0, 0, Paths.image('menus/funkay'));
        loadingImage.setGraphicSize(0, FlxG.height);
        loadingImage.updateHitbox();
        loadingImage.screenCenter();
        add(loadingImage);

        loadingBar = new FlxBar(0, FlxG.height - 26, FlxBarFillDirection.LEFT_TO_RIGHT, FlxG.width, 26);
        loadingBar.setRange(0, maxLoopTimes);
        add(loadingBar);

        loadedText = new FlxText(loadingBar.x, loadingBar.y + 4, FlxG.width, '', 16);
        loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        add(loadedText);

        thread = new ThreadPool(0, CoolUtil.getCPUThreadsCount());
        thread.doWork.add(function(poop) {
            for (file in locatedFiles) {
                loopTimes++;
                // Commented out copying logic to avoid external storage usage
                // copyAsset(file);
            }
        });
        new FlxTimer().start(0.5, (tmr) -> {
            thread.queue({});
        });

        super.create();
    }

    override function update(elapsed:Float) {
        if (shouldCopy) {
            if (loopTimes >= maxLoopTimes && canUpdate) {
                if (failedFiles.length > 0) {
                    NativeAPI.showMessageBox('Failed to Verify ${failedFiles.length} File(s).', failedFiles.join('\n'), MSG_ERROR);
                }

                FlxG.sound.play(Paths.sound('menu/confirm')).onComplete = () -> {
                    FlxG.resetGame();
                };

                canUpdate = false;
            }

            if (loopTimes >= maxLoopTimes)
                loadedText.text = "Verification Completed!";
            else
                loadedText.text = '$loopTimes/$maxLoopTimes';

            loadingBar.percent = Math.min((loopTimes / maxLoopTimes) * 100, 100);
        }
        super.update(elapsed);
    }

    // Commented out to avoid copying files to external storage
    /*
    public function copyAsset(file:String) {
        if (!FileSystem.exists(file)) {
            var directory = Path.directory(file);
            if (!FileSystem.exists(directory))
                FileSystem.createDirectory(directory);
            try {
                if (OpenFLAssets.exists(getFile(file))) {
                    if (textFilesExtensions.contains(Path.extension(file)))
                        createContentFromInternal(file);
                    else {
                        var path:String = file;
                        File.saveBytes(path, getFileBytes(getFile(file)));
                    }
                } else {
                    failedFiles.push(getFile(file) + " (File Doesn't Exist)");
                    failedFilesStack.push('Asset ${getFile(file)} does not exist.');
                }
            } catch (e:haxe.Exception) {
                failedFiles.push('${getFile(file)} (${e.message})');
                failedFilesStack.push('${getFile(file)} (${e.stack})');
            }
        }
    }
    */

    public function getFileBytes(file:String):ByteArray {
        return OpenFLAssets.getBytes(file);
    }

    public static function getFile(file:String):String {
        if (OpenFLAssets.exists(file))
            return file;

        @:privateAccess
        for (library in LimeAssets.libraries.keys()) {
            if (OpenFLAssets.exists('$library:$file') && library != 'default')
                return '$library:$file';
        }

        return file;
    }

    public static function checkExistingFiles():Bool {
        locatedFiles = Paths.assetsTree.list(null);

        // Filter assets to only include internal files
        locatedFiles = locatedFiles.filter(folder -> folder.startsWith('assets/'));

        var filesToRemove:Array<String> = [];

        for (file in locatedFiles) {
            if (filesToRemove.contains(file))
                continue;

            if (file.endsWith(IGNORE_FOLDER_FILE_NAME) && !directoriesToIgnore.contains(Path.directory(file)))
                directoriesToIgnore.push(Path.directory(file));

            if (directoriesToIgnore.length > 0) {
                for (directory in directoriesToIgnore) {
                    if (file.startsWith(directory))
                        filesToRemove.push(file);
                }
            }
        }

        locatedFiles = locatedFiles.filter(file -> !filesToRemove.contains(file));

        maxLoopTimes = locatedFiles.length;

        return (maxLoopTimes <= 0);
    }
}
#end