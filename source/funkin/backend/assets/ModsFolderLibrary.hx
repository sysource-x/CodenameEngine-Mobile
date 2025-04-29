package funkin.backend.assets;

import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;

import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

#if MOD_SUPPORT
import sys.FileStat;
import sys.FileSystem;
#end

using StringTools;

class ModsFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var folderPath:String;
    public var modName:String;
    public var libName:String;
    public var useImageCache:Bool = true;
    public var prefix = 'assets/';

    public function new(folderPath:String, libName:String, ?modName:String) {
        this.folderPath = folderPath;
        this.libName = libName;
        this.prefix = 'assets/$libName/';
        if (modName == null)
            this.modName = libName;
        else
            this.modName = modName;
        super();
    }

    #if MOD_SUPPORT
    private var editedTimes:Map<String, Float> = [];
    public var _parsedAsset:String = null;

    public function getEditedTime(asset:String):Null<Float> {
        return editedTimes[asset];
    }

    public override function getAudioBuffer(id:String):AudioBuffer {
        if (!exists(id, "SOUND"))
            return null;
        var path = getAssetPath();
        #if mobile
        var data = Assets.getBytes('assets/' + path);
        if (data != null)
            return AudioBuffer.fromBytes(data);
        return null;
        #else
        editedTimes[id] = FileSystem.stat(path).mtime.getTime();
        return AudioBuffer.fromFile(path);
        #end
    }

    public override function getBytes(id:String):Bytes {
        if (!exists(id, "BINARY"))
            return null;
        var path = getAssetPath();
        #if mobile
        return Assets.getBytes('assets/' + path);
        #else
        editedTimes[id] = FileSystem.stat(path).mtime.getTime();
        return Bytes.fromFile(path);
        #end
    }

    public override function getFont(id:String):Font {
        if (!exists(id, "FONT"))
            return null;
        var path = getAssetPath();
        #if mobile
        var bytes = Assets.getBytes('assets/' + path);
        if (bytes != null)
            return ModsFolder.registerFont(Font.fromBytes(bytes));
        return null;
        #else
        editedTimes[id] = FileSystem.stat(path).mtime.getTime();
        return ModsFolder.registerFont(Font.fromFile(path));
        #end
    }

    public override function getImage(id:String):Image {
        if (!exists(id, "IMAGE"))
            return null;
        var path = getAssetPath();
        #if mobile
        return Assets.getImage('assets/' + path);
        #else
        editedTimes[id] = FileSystem.stat(path).mtime.getTime();
        return Image.fromFile(path);
        #end
    }
    #end

	public override function getPath(id:String):String {
		if (!__parseAsset(id)) return null;
		return getAssetPath();
	}

	public inline function getFolders(folder:String):Array<String>
		return __getFiles(folder, true);

	public inline function getFiles(folder:String):Array<String>
		return __getFiles(folder, false);

	public function __getFiles(folder:String, folders:Bool = false):Array<String> {
		if (!folder.endsWith("/")) folder = folder + "/";
		
		#if mobile
		// Em mobile, lemos a lista manualmente
		try {
			var cleanFolder = folder;
			if (cleanFolder.startsWith("assets/")) cleanFolder = cleanFolder.substr(7); // tira o 'assets/' se tiver
			var listPath = 'assets/${cleanFolder}filesList.json'; // exemplo: assets/mods/filesList.json
			
			if (Assets.exists(listPath, AssetType.TEXT)) {
				var content = Assets.getText(listPath);
				var allFiles:Array<String> = Json.parse(content);
				var result:Array<String> = [];
				
				for (e in allFiles) {
					// Se for pasta (termina com '/')
					var isFolder = e.endsWith('/');
					if (isFolder == folders) {
						// Se está pedindo só pastas ou só arquivos
						result.push(e.substr(0, e.length - (isFolder ? 1 : 0))); // Remove '/' no final de pastas
					}
				}
				return result;
			}
		} catch(e) {
			trace('Erro carregando lista de arquivos: ' + e);
		}
		return [];
		
		#else
		// No PC continua usando FileSystem normal
		if (!__parseAsset(folder)) return [];
		var path = getAssetPath();
		try {
			var result:Array<String> = [];
			for (e in FileSystem.readDirectory(path)) {
				if (FileSystem.isDirectory('$path$e') == folders)
					result.push(e);
			}
			return result;
		} catch (e) {
			trace('Erro lendo diretório: ' + e);
		}
		return [];
		#end
	}	

	public override function exists(asset:String, type:String):Bool {
		if (!__parseAsset(asset)) return false;
		#if mobile
		var path = 'assets/' + folderPath + '/' + _parsedAsset;
		return Assets.exists(path, getAssetType(type));
		#else
		return FileSystem.exists(getAssetPath());
		#end
	}
	
	private function getAssetPath():String {
		return '$folderPath/$_parsedAsset';
	}
	
	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocalCache:Bool = false):Bool {
		#if mobile
		// Em mobile, não conseguimos verificar a edição do arquivo, então confiamos no cache interno
		if (!editedTimes.exists(asset))
			return false;
		if (!isLocalCache) asset = '$libName:$asset';
		return cache.exists(asset) && cache[asset] != null;
		#else
		if (!editedTimes.exists(asset))
			return false;
		if (editedTimes[asset] == null || editedTimes[asset] < FileSystem.stat(getPath(asset)).mtime.getTime()) {
			// destroy already existing to prevent memory leak!!!
			var assetObj = cache[asset];
			if (assetObj != null) {
				switch(Type.getClass(assetObj)) {
					case lime.graphics.Image:
						trace("getting rid of image cause replaced");
						cast(assetObj, lime.graphics.Image);
				}
			}
			return false;
		}
	
		if (!isLocalCache) asset = '$libName:$asset';
		return cache.exists(asset) && cache[asset] != null;
		#end
	}	

	private function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		if(ModsFolder.useLibFile) {
			var file = new haxe.io.Path(_parsedAsset);
			if(file.file.startsWith("LIB_")) {
				var library = file.file.substr(4);
				if(library != modName) return false;

				_parsedAsset = file.dir + "." + file.ext;
			}
		}
		return true;
	}
	#end
}