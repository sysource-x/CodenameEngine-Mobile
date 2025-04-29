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

package mobile.funkin.backend.utils;

#if TOUCH_CONTROLS
import haxe.ds.Map;
import haxe.Json;
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.util.FlxSave;

/**
 * ...
 * @author: Karim Akra
 */
class MobileData {
    public static var actionModes:Map<String, TouchButtonsData> = new Map();
    public static var dpadModes:Map<String, TouchButtonsData> = new Map();

    public static var save:FlxSave;

    public static function init() {
        save = new FlxSave();
        save.bind('MobileControls', #if sys 'YoshiCrafter29/CodenameEngine' #else 'CodenameEngine' #end);

        // Ajustado para usar apenas arquivos internos
        for (folder in [
            'assets/mobile',
            'assets/${ModsFolder.currentModFolder}/mobile'
        ]) {
            if (Assets.exists(folder)) {
                setMap('$folder/DPadModes', dpadModes);
                setMap('$folder/ActionModes', actionModes);
            }
        }
    }

    public static function setMap(folder:String, map:Map<String, TouchButtonsData>) {
        var fileList = Assets.list(folder); // Lista arquivos no diretório interno
        for (file in fileList) {
            if (Path.extension(file) == 'json') {
                var filePath = '$folder/$file';
                if (Assets.exists(filePath)) {
                    var str = Assets.getText(filePath);
                    var json:TouchButtonsData = cast Json.parse(str);
                    var mapKey:String = Path.withoutExtension(file);
                    map.set(mapKey, json);
                }
            }
        }
    }
}

typedef TouchButtonsData = {
    buttons:Array<ButtonsData>
}

typedef ButtonsData = {
    button:String, // The button to be used, must be a valid TouchButton var from TouchPad as a string.
    graphic:String, // The graphic of the button, usually located in the TouchPad XML.
    x:Float, // The button's X position on screen.
    y:Float, // The button's Y position on screen.
    color:String // The button color, default color is white.
}
#end
