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

/**
 * A storage class for mobile.
 * Adjusted to work exclusively with internal assets.
 */
class StorageUtil {
    #if sys
    public static function getStorageDirectory():String {
        // Ajustado para retornar o diretório interno de assets
        return "assets/";
    }

    #if android
    // Retorna um caminho interno fixo para evitar manipulação de armazenamento externo
    public static function getExternalStorageDirectory():String {
        return "assets/internal/";
    }

    public static function requestPermissions():Void {
        // Removido o pedido de permissões externas
        trace("External storage permissions are not required for internal-only assets.");

        // Verifica se o diretório interno existe
        try {
            if (!Assets.exists(getStorageDirectory())) {
                trace("Internal storage directory does not exist. Ensure assets are properly bundled.");
            }
        } catch (e:Dynamic) {
            NativeAPI.showMessageBox(
                "Error!",
                "Internal storage directory is missing.\nPlease ensure the assets are properly bundled.\nPress OK to close the game."
            );
            lime.system.System.exit(1);
        }
    }
    #end
    #end
}