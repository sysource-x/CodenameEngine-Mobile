package funkin.backend.utils;

#if sys
#if (!macro && sys)
import openfl.display.BitmapData;
#end

import haxe.Exception;
import haxe.Json;
import haxe.crypto.Crc32;
import haxe.zip.Writer;
import haxe.zip.Tools;
import haxe.zip.Entry;
import haxe.zip.Uncompress;
import haxe.zip.Reader;
import haxe.zip.Compress;
import lime.utils.Assets; // Substitui FileSystem para trabalhar com arquivos internos
using StringTools;

class ZipUtil {
    public static var bannedNames:Array<String> = [".git", ".gitignore", ".github", ".vscode", ".gitattributes", "readme.txt"];

    /**
     * [Description] Uncompresses `zip` into the `destFolder` folder (adjusted for internal assets)
     * @param zip
     * @param destFolder
     */
    public static function uncompressZip(zip:Reader, destFolder:String, ?prefix:String, ?prog:ZipProgress):ZipProgress {
        trace("Uncompressing ZIP files is not supported for internal assets.");
        return null;
    }

    #if (!macro && sys)
    public static function uncompressZipAsync(zip:Reader, destFolder:String, ?prog:ZipProgress, ?prefix:String):ZipProgress {
        trace("Uncompressing ZIP files asynchronously is not supported for internal assets.");
        return null;
    }
    #end

    /**
     * [Description] Returns a `zip.Reader` instance from path (adjusted for internal assets).
     * @param zipPath
     * @return Reader
     */
    public static function openZip(zipPath:String):Reader {
        if (!Assets.exists(zipPath)) {
            throw "ZIP file not found in assets: $zipPath";
        }
        return new ZipReader(Assets.getBytes(zipPath));
    }

    /**
     * [Description] Copy of haxe's Zip unzip function cause lime replaced it.
     * @param f Zip entry
     */
    public static function unzip(f:Entry) {
        if (!f.compressed)
            return f.data;
        var c = new haxe.zip.Uncompress(-15);
        var s = haxe.io.Bytes.alloc(f.fileSize);
        var r = c.execute(f.data, 0, s, 0);
        c.close();
        if (!r.done || r.read != f.data.length || r.write != f.fileSize)
            throw "Invalid compressed data for " + f.fileName;
        f.compressed = false;
        f.dataSize = f.fileSize;
        f.data = s;
        return f.data;
    }

    /**
     * [Description] Creates a ZIP file at the specified location and returns the Writer (adjusted for internal assets).
     * @param path
     * @return Writer
     */
    public static function createZipFile(path:String):ZipWriter {
        trace("Creating ZIP files is not supported for internal assets.");
        return null;
    }

    /**
     * [Description] Writes the entirety of a folder to a zip file (adjusted for internal assets).
     * @param zip ZIP file to write to
     * @param path Folder path
     * @param prefix (Additional) allows you to set a prefix in the zip itself.
     */
    public static function writeFolderToZip(zip:ZipWriter, path:String, ?prefix:String, ?prog:ZipProgress, ?whitelist:Array<String>):ZipProgress {
        trace("Writing folders to ZIP files is not supported for internal assets.");
        return null;
    }

    public static function writeFolderToZipAsync(zip:ZipWriter, path:String, ?prefix:String):ZipProgress {
        trace("Writing folders to ZIP files asynchronously is not supported for internal assets.");
        return null;
    }

    /**
     * [Description] Converts an `Array<Entry>` to a `List<Entry>`.
     * @param array
     * @return List<Entry>
     */
    public static function arrayToList(array:Array<Entry>):List<Entry> {
        var list = new List<Entry>();
        for (e in array) list.push(e);
        return list;
    }
}

class ZipProgress {
    public var error:Exception = null;

    public var curFile:Int = 0;
    public var fileCount:Int = 0;
    public var done:Bool = false;
    public var percentage(get, null):Float;

    private function get_percentage() {
        return fileCount <= 0 ? 0 : curFile / fileCount;
    }

    public function new() {}
}

class ZipReader extends Reader {
    public var files:List<Entry>;

    public override function read() {
        if (files != null) return files;
        try {
            var files = super.read();
            return this.files = files;
        } catch (e) {
        }
        return new List<Entry>();
    }
}

class ZipWriter extends Writer {
    public function flush() {
        o.flush();
    }

    public function writeFile(entry:Entry) {
        writeEntryHeader(entry);
        o.writeFullBytes(entry.data, 0, entry.data.length);
    }

    public function close() {
        o.close();
    }
}

class StrNameLabel {
    public var name:String;
    public var label:String;

    public function new(name:String, label:String) {
        this.name = name;
        this.label = label;
    }
}
#end