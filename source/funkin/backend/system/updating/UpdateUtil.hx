package funkin.backend.system.updating;

import haxe.io.Path;
import funkin.backend.system.github.GitHubRelease;
import funkin.backend.system.github.GitHub;
import lime.app.Application;

using funkin.backend.system.github.GitHub;

class UpdateUtil {
    public static final repoOwner:String = "YoshiCrafter29";
    public static final repoName:String = "CodenameTestRepo";

    public static function init() {
        // Removido o uso de FileSystem para manipulação de arquivos externos
        trace("UpdateUtil initialized. No external storage operations are required.");
    }

    public static function checkForUpdates():UpdateCheckCallback {
        var curTag = 'v${Application.current.meta.get("version")}';
        trace("Current version tag: " + curTag);

        var error = false;

        var newUpdates = __doReleaseFiltering(GitHub.getReleases(repoOwner, repoName, function(e) {
            error = true;
            trace("Error fetching releases: " + e);
        }), curTag);

        if (error) return {
            success: false,
            newUpdate: false
        };

        if (newUpdates.length <= 0) {
            return {
                success: true,
                newUpdate: false
            };
        }

        return {
            success: true,
            newUpdate: true,
            currentVersionTag: curTag,
            newVersionTag: newUpdates.last().tag_name,
            updates: newUpdates
        };
    }

    static var __curVersionPos = -2;

    static function __doReleaseFiltering(releases:Array<GitHubRelease>, currentVersionTag:String) {
        releases = releases.filterReleases(Options.betaUpdates, false);
        if (releases.length <= 0)
            return releases;

        var newArray:Array<GitHubRelease> = [];

        var skipNextBinaryChecks:Bool = false;
        for (index in 0...releases.length) {
            var i = index;

            var release = releases[i];
            var containsBinary = skipNextBinaryChecks;
            if (!containsBinary) {
                for (asset in release.assets) {
                    if (asset.name.toLowerCase() == AsyncUpdater.executableGitHubName.toLowerCase()) {
                        containsBinary = true;
                        break;
                    }
                }
            }
            if (containsBinary) {
                skipNextBinaryChecks = true; // no need to check for older versions
                if (release.tag_name == currentVersionTag) {
                    __curVersionPos = -1;
                }
                newArray.insert(0, release);
                if (__curVersionPos > -2)
                    __curVersionPos++;
                trace("Release found: " + release.tag_name);
            }
        }
        if (__curVersionPos < -1)
            __curVersionPos = -1;

        return newArray.length <= 0 ? newArray : newArray.splice(__curVersionPos + 1, newArray.length - (__curVersionPos + 1));
    }
}

typedef UpdateCheckCallback = {
    var success:Bool;

    var newUpdate:Bool;

    @:optional var currentVersionTag:String;

    @:optional var newVersionTag:String;

    @:optional var updates:Array<GitHubRelease>;
}