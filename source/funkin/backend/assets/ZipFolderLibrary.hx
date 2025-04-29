package funkin.backend.assets;

import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

#if MOD_SUPPORT

using StringTools;

class ZipFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
    public var modName:String;
    public var libName:String;
    public var useImageCache:Bool = false;
    public var prefix = 'assets/';

    public var assets:Map<String, Bytes> = []; // Store unzipped assets in memory

    public function new(zipPath:String, libName:String, ?modName:String) {
        this.libName = libName;

        if (modName == null)
            this.modName = libName;
        else
            this.modName = modName;

        // Load assets from the internal directory
        loadAssetsFromInternal(zipPath);
        super();
    }

    /**
     * Loads assets from the internal directory (assets/).
     */
    private function loadAssetsFromInternal(zipPath:String) {
        var assetList = LimeAssets.list(zipPath);

        for (asset in assetList) {
            var fullPath = '$zipPath/$asset';
            if (LimeAssets.exists(fullPath)) {
                assets[asset.toLowerCase()] = LimeAssets.getBytes(fullPath);
            }
        }
    }

    public var _parsedAsset:String;

    public override function getAudioBuffer(id:String):AudioBuffer {
        __parseAsset(id);
        return AudioBuffer.fromBytes(assets[_parsedAsset]);
    }

    public override function getBytes(id:String):Bytes {
        __parseAsset(id);
        return assets[_parsedAsset];
    }

    public override function getFont(id:String):Font {
        __parseAsset(id);
        return ModsFolder.registerFont(Font.fromBytes(assets[_parsedAsset]));
    }

    public override function getImage(id:String):Image {
        __parseAsset(id);
        return Image.fromBytes(assets[_parsedAsset]);
    }

    public override function getPath(id:String):String {
        if (!__parseAsset(id)) return null;
        return getAssetPath();
    }

    private function getAssetPath() {
        return '[INTERNAL]$prefix$_parsedAsset';
    }

    public function __parseAsset(asset:String):Bool {
        if (!asset.startsWith(prefix)) return false;
        _parsedAsset = asset.substr(prefix.length).toLowerCase();
        return assets.exists(_parsedAsset);
    }

    public function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false) {
        return cache.exists(asset);
    }

    public override function exists(asset:String, type:String):Bool {
        if (!__parseAsset(asset)) return false;
        return assets.exists(_parsedAsset);
    }

    public function getFiles(folder:String):Array<String> {
        var content:Array<String> = [];

        if (!folder.endsWith("/")) folder = folder + "/";
        if (!__parseAsset(folder)) return [];

        for (k in assets.keys()) {
            if (k.startsWith(_parsedAsset)) {
                var fileName = k.substr(_parsedAsset.length);
                if (!fileName.contains("/"))
                    content.push(fileName);
            }
        }
        return content;
    }

    public function getFolders(folder:String):Array<String> {
        var content:Array<String> = [];

        if (!folder.endsWith("/")) folder = folder + "/";
        if (!__parseAsset(folder)) return [];

        for (k in assets.keys()) {
            if (k.startsWith(_parsedAsset)) {
                var fileName = k.substr(_parsedAsset.length);
                if (fileName.contains("/")) {
                    var s = fileName.split("/")[0];
                    if (!content.contains(s))
                        content.push(s);
                }
            }
        }
        return content;
    }
}
#end