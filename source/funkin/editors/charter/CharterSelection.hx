package funkin.editors.charter;

import funkin.backend.chart.ChartData;
import funkin.backend.chart.ChartData.ChartMetaData;
import haxe.Json;
import funkin.editors.charter.SongCreationScreen.SongCreationData;
import funkin.options.type.NewOption;
import funkin.backend.system.framerate.Framerate;
import funkin.menus.FreeplayState.FreeplaySonglist;
import funkin.editors.EditorTreeMenu;
import funkin.options.*;
import funkin.options.type.*;

using StringTools;

class CharterSelection extends EditorTreeMenu {
    public var freeplayList:FreeplaySonglist;
    public var curSong:ChartMetaData;
    private final button:String = controls.touchC ? 'A' : 'ACCEPT';

    public override function create() {
        bgType = "charter";

        super.create();

        Framerate.offset.y = 60;

        freeplayList = FreeplaySonglist.get(false);

        var list:Array<OptionType> = [
            for (s in freeplayList.songs) new EditorIconOption(s.name, "Press " + button + " to choose a difficulty to edit.", s.icon, function() {
                curSong = s;
                var list:Array<OptionType> = [
                    for (d in s.difficulties) if (d != "")
                        new TextOption(d, "Press " + button + " to edit the chart for the selected difficulty", function() {
                            #if TOUCH_CONTROLS
                            if (funkin.backend.system.Controls.instance.touchC) {
                                openSubState(new UIWarningSubstate("Charter: Touch Not Supported!", "Please connect a keyboard and mouse to access this editor.", [
                                    {label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
                                ]));
                            } else
                            #end
                            FlxG.switchState(new Charter(s.name, d));
                        })
                ];
                list.push(new NewOption("New Difficulty", "New Difficulty", function() {
                    #if TOUCH_CONTROLS
                    if (funkin.backend.system.Controls.instance.touchC) {
                        openSubState(new UIWarningSubstate("New Difficulty: Touch Not Supported!", "Please connect a keyboard and mouse to access this editor.", [
                            {label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
                        ]));
                    } else
                    #end
                    FlxG.state.openSubState(new ChartCreationScreen(saveChart));
                }));
                optionsTree.add(new OptionsScreen(s.name, "Select a difficulty to continue.", list, 'UP_DOWN', 'A_B'));
            }, s.parsedColor.getDefault(0xFFFFFFFF))
        ];

        list.insert(0, new NewOption("New Song", "New Song", function() {
            #if TOUCH_CONTROLS
            if (funkin.backend.system.Controls.instance.touchC) {
                openSubState(new UIWarningSubstate("New Song: Touch Not Supported!", "Please connect a keyboard and mouse to access this editor.", [
                    {label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
                ]));
            } else
            #end
            FlxG.state.openSubState(new SongCreationScreen(saveSong));
        }));

        main = new OptionsScreen("Chart Editor", "Select a song to modify the charts from.", list, 'UP_DOWN', 'A_B');

        DiscordUtil.call("onEditorTreeLoaded", ["Chart Editor"]);
    }

    override function createPost() {
        super.createPost();

        main.changeSelection(1);
    }

    public override function update(elapsed:Float) {
        super.update(elapsed);

        bg.colorTransform.redOffset = lerp(bg.colorTransform.redOffset, 0, 0.0625);
        bg.colorTransform.greenOffset = lerp(bg.colorTransform.greenOffset, 0, 0.0625);
        bg.colorTransform.blueOffset = lerp(bg.colorTransform.blueOffset, 0, 0.0625);
        bg.colorTransform.redMultiplier = lerp(bg.colorTransform.redMultiplier, 1, 0.0625);
        bg.colorTransform.greenMultiplier = lerp(bg.colorTransform.greenMultiplier, 1, 0.0625);
        bg.colorTransform.blueMultiplier = lerp(bg.colorTransform.blueMultiplier, 1, 0.0625);
    }

    public override function onMenuChange() {
        super.onMenuChange();
        if (optionsTree.members.length > 1) { // selected a song
            if (main != null) {
                var opt = main.members[main.curSelected];
                if (opt is EditorIconOption) {
                    var opt:EditorIconOption = cast opt;

                    // small flashbang
                    var color = opt.flashColor;
                    bg.colorTransform.redOffset = 0.25 * color.red;
                    bg.colorTransform.greenOffset = 0.25 * color.green;
                    bg.colorTransform.blueOffset = 0.25 * color.blue;
                    bg.colorTransform.redMultiplier = FlxMath.lerp(1, color.redFloat, 0.25);
                    bg.colorTransform.greenMultiplier = FlxMath.lerp(1, color.greenFloat, 0.25);
                    bg.colorTransform.blueMultiplier = FlxMath.lerp(1, color.blueFloat, 0.25);
                }
            }
        }
    }

    public function saveSong(creation:SongCreationData) {
        var songAlreadyExists:Bool = [for (s in freeplayList.songs) s.name.toLowerCase()].contains(creation.meta.name.toLowerCase());

        if (songAlreadyExists) {
            openSubState(new UIWarningSubstate("Creating Song: Error!", "The song you are trying to create already exists. If you would like to override it, delete the song first!", [
                {label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
            ]));
            return;
        }

        // Paths
        var songsDir:String = '${Paths.getAssetsRoot()}/songs/';
        var songFolder:String = '$songsDir${creation.meta.name}';

        // Salvar arquivos diretamente na memória ou em um local permitido
        trace("Saving song data is not supported for internal assets.");
    }

    public function saveChart(name:String, data:ChartData) {
        var difficultyAlreadyExists:Bool = curSong.difficulties.contains(name);

        if (difficultyAlreadyExists) {
            openSubState(new UIWarningSubstate("Creating Chart: Error!", "The chart you are trying to create already exists. If you would like to override it, delete the chart first!", [
                {label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
            ]));
            return;
        }

        // Paths
        var songFolder:String = '${Paths.getAssetsRoot()}/songs/${curSong.name}';

        // Salvar arquivos diretamente na memória ou em um local permitido
        trace("Saving chart data is not supported for internal assets.");
    }
}