/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2022, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Cocoa

public class MainWindowController: NSWindowController
{
    @IBOutlet private var configTextView: NSTextView!
    @IBOutlet private var codeTextView:   NSTextView!

    @objc private dynamic var config = ""
    @objc private dynamic var code   = ""

    private var cacheDirectory:  URL?
    private var configCacheFile: URL?
    private var codeCacheFile:   URL?
    private var windowObserver:  Any?

    public init()
    {
        super.init( window: nil )
    }

    required init?( coder: NSCoder )
    {
        nil
    }

    public override var windowNibName: NSNib.Name?
    {
        "MainWindowController"
    }

    public override func windowDidLoad()
    {
        super.windowDidLoad()

        self.configureTextView( self.configTextView )
        self.configureTextView( self.codeTextView )

        if let cacheDirectory = NSSearchPathForDirectoriesInDomains( .cachesDirectory, .userDomainMask, true ).first,
           let bundleID       = Bundle.main.bundleIdentifier
        {
            let cacheDirectory   = URL( fileURLWithPath: cacheDirectory ).appendingPathComponent( bundleID )
            self.cacheDirectory  = cacheDirectory
            self.configCacheFile = self.cacheDirectory?.appendingPathComponent( "config.cfg" )
            self.codeCacheFile   = self.cacheDirectory?.appendingPathComponent( "code.txt" )

            try? FileManager.default.createDirectory( at: cacheDirectory, withIntermediateDirectories: true )
        }

        self.restoreState()

        self.windowObserver = NotificationCenter.default.addObserver( forName: NSWindow.willCloseNotification, object: self.window, queue: nil )
        {
            [ weak self ] _ in self?.saveState()
        }
    }

    @IBAction
    private func loadConfig( _ sender: Any? )
    {
        self.chooseFile
        {
            do
            {
                if let url = $0
                {
                    self.config = try self.readFile( url: url )
                }
            }
            catch
            {
                self.displayError( error )
            }
        }
    }

    @IBAction
    private func exportConfig( _ sender: Any? )
    {
        guard let data = self.config.data( using: .utf8 )
        else
        {
            self.displayError( message: "Cannot export configuration as UTF-8 text." )

            return
        }

        self.saveFile( data: data, name: "config", extension: "cfg" )
    }

    @IBAction
    private func loadCode( _ sender: Any? )
    {
        self.chooseFile
        {
            do
            {
                if let url = $0
                {
                    self.code = try self.readFile( url: url )
                }
            }
            catch
            {
                self.displayError( error )
            }
        }
    }

    @IBAction
    private func format( _ sender: Any? )
    {
        self.saveState()

        guard let cacheDirectory = self.cacheDirectory,
              let config         = self.configCacheFile,
              let code           = self.codeCacheFile
        else
        {
            self.displayError( title: "No Caches Directory", message: "The application's caches directory does not exists, or failed to be created." )

            return
        }

        let exec = "/opt/homebrew/bin/uncrustify"

        guard FileManager.default.fileExists( atPath: exec )
        else
        {
            self.displayError( title: "Cannot find Uncrustify", message: "The Uncrustify executable was not found in: \( exec )" )

            return
        }

        let temp        = cacheDirectory.appendingPathComponent( "format.txt" )
        let task        = Process()
        task.launchPath = exec
        task.arguments  =
            [
                "-c", config.path,
                "-f", code.path,
                "-o", temp.path,
            ]

        task.launch()
        task.waitUntilExit()

        self.code = ( try? self.readFile( url: temp ) ) ?? ""
    }

    private func configureTextView( _ view: NSTextView )
    {
        view.font               = NSFont.monospacedSystemFont( ofSize: 12, weight: .regular )
        view.textContainerInset = NSSize( width: 10, height: 10 )
    }

    private func readFile( url: URL ) throws -> String
    {
        let data = try Data( contentsOf: url )

        guard let text = String( data: data, encoding: .utf8 )
        else
        {
            throw NSError( title: "Cannot Read File", message: "The file \( url.lastPathComponent ) cannot be read as UTF-8 text." )
        }

        return text
    }

    private func saveState()
    {
        if let url = self.configCacheFile, let data = self.config.data( using: .utf8 )
        {
            try? data.write( to: url )
        }

        if let url = self.codeCacheFile, let data = self.code.data( using: .utf8 )
        {
            try? data.write( to: url )
        }
    }

    private func restoreState()
    {
        if let url = self.configCacheFile, let text = try? self.readFile( url: url )
        {
            self.config = text
        }

        if let url = self.codeCacheFile, let text = try? self.readFile( url: url )
        {
            self.code = text
        }
    }
}
