package funkin.backend.system;

#if MOD_SUPPORT
import sys.FileSystem;
#end
import funkin.backend.assets.ModsFolder;
import funkin.menus.TitleState;
import funkin.menus.BetaWarningState;
import funkin.backend.chart.EventsData;
import flixel.FlxState;
#if mobile
import mobile.funkin.backend.system.CopyState;
#end

/**
 * Simple state used for loading the game
 */
class MainState extends FlxState {
    public static var initiated:Bool = false;
    public static var betaWarningShown:Bool = false;

    public override function create() {
        super.create();

        #if mobile
        funkin.backend.system.Main.framerateSprite.setScale();
        #end

        if (!initiated) {
            Main.loadGameSettings();

            #if mobile
            if (!CopyState.checkExistingFiles()) {
                FlxG.switchState(new CopyState());
                return;
            }
			// Verificação de arquivos internos
            //if (!LimeAssets.exists("assets/some_required_file")) {
            //    throw "Required internal file is missing!";
            //}
            #end

            #if TOUCH_CONTROLS
            mobile.funkin.backend.utils.MobileData.init();
            #end
        }

        initiated = true;

        #if sys
        // Comentado para evitar manipulação de arquivos externos
        // CoolUtil.deleteFolder('.temp/'); // delete temp folder
        #end

        Options.save();

        FlxG.bitmap.reset();
        FlxG.sound.destroy(true);

        Paths.assetsTree.reset();

        #if MOD_SUPPORT
        var _lowPriorityAddons:Array<String> = [];
        var _highPriorityAddons:Array<String> = [];
        var _noPriorityAddons:Array<String> = [];

        // Substituir manipulação de arquivos externos por verificações internas
        if (LimeAssets.exists(ModsFolder.addonsPath)) {
            var addonList = LimeAssets.list(ModsFolder.addonsPath);
            for (addon in addonList) {
                if (addon.startsWith("[LOW]")) _lowPriorityAddons.insert(0, addon);
                else if (addon.startsWith("[HIGH]")) _highPriorityAddons.insert(0, addon);
                else _noPriorityAddons.insert(0, addon);
            }

            for (addon in _lowPriorityAddons)
                Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon', StringTools.ltrim(addon.substr("[LOW]".length))));
        }

        if (ModsFolder.currentModFolder != null)
            Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.modsPath}${ModsFolder.currentModFolder}', ModsFolder.currentModFolder));

        if (LimeAssets.exists(ModsFolder.addonsPath)) {
            for (addon in _noPriorityAddons)
                Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon', addon));
            for (addon in _highPriorityAddons)
                Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon', StringTools.ltrim(addon.substr("[HIGH]".length))));
        }
        #end

        MusicBeatTransition.script = "";
        Main.refreshAssets();
        ModsFolder.onModSwitch.dispatch(ModsFolder.currentModFolder);
        DiscordUtil.init();
        EventsData.reloadEvents();
        TitleState.initialized = false;

        if (betaWarningShown)
            FlxG.switchState(new TitleState());
        else {
            FlxG.switchState(new BetaWarningState());
            betaWarningShown = true;
        }

        // Comentado para evitar manipulação de arquivos externos
        // CoolUtil.safeAddAttributes('./.temp/', NativeAPI.FileAttribute.HIDDEN);
    }
}