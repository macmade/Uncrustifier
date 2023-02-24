/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2023, Jean-David Gadina - www.xs-labs.com
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
import Highlightr

public class MainWindowController: NSWindowController, NSMenuDelegate
{
    @IBOutlet private var configContainer: NSView!
    @IBOutlet private var codeContainer:   NSView!
    @IBOutlet private var optionsMenu:     NSMenu!

    @objc private dynamic var configController = ConfigViewController()
    @objc private dynamic var codeController   = TextViewController()

    @objc private dynamic var language = UserDefaults.standard.integer( forKey: "language" )
    {
        didSet
        {
            UserDefaults.standard.set( self.language, forKey: "language" )

            if let language = Uncrustify.Language( rawValue: self.language )
            {
                self.codeController.setLanguage( language )
            }
        }
    }

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

        if UserDefaults.standard.string( forKey: "theme" ) == nil
        {
            UserDefaults.standard.set( "vs2015", forKey: "theme" )
        }

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

        self.configContainer.addFillingSubview( self.configController.view )
        self.codeContainer.addFillingSubview( self.codeController.view )
        self.codeController.setAsFirstResponder()

        if let language = Uncrustify.Language( rawValue: self.language )
        {
            self.codeController.setLanguage( language )
        }
    }

    @IBAction
    private func showOptions( _ sender: Any? )
    {
        guard let view  = sender as? NSView,
              let event = NSApp.currentEvent
        else
        {
            NSSound.beep()

            return
        }

        NSMenu.popUpContextMenu( self.optionsMenu, with: event, for: view )
    }

    @IBAction
    private func loadConfig( _ sender: Any? )
    {
        self.chooseFile
        {
            guard let url = $0
            else
            {
                return
            }

            guard let config = Config( url: url )
            else
            {
                self.displayError( title: "Invalid Config", message: "Cannot read configuration file at \( url.path )." )
                return
            }

            self.configController.config = config
        }
    }

    @IBAction
    private func exportConfig( _ sender: Any? )
    {
        self.saveFile( data: self.configController.config.data, name: "config", extension: "cfg" )
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
                    self.codeController.text = try self.readFile( url: url )
                }
            }
            catch
            {
                self.displayError( error )
            }
        }
    }

    @IBAction
    private func reloadDefaultConfig( _ sender: Any? )
    {
        guard let config = try? Uncrustify.defaultConfig()
        else
        {
            self.displayError( message: "Cannot load the default Uncrustify configuration." )

            return
        }

        self.configController.config = Config( text: config )
    }

    @IBAction
    private func reloadExampleCode( _ sender: Any? )
    {
        guard let url  = Bundle.main.url( forResource: "CFBase", withExtension: "txt" ),
              let code = try? self.readFile( url: url )
        else
        {
            self.displayError( message: "Cannot load the example code file." )

            return
        }

        self.codeController.text = code
        self.language            = 0
    }

    @IBAction
    private func format( _ sender: Any? )
    {
        self.saveState()

        DispatchQueue.main.async
        {
            guard let config = self.configCacheFile,
                  let code   = self.codeCacheFile
            else
            {
                self.displayError( title: "No Caches Directory", message: "The application's caches directory does not exists, or failed to be created." )

                return
            }

            do
            {
                let text = try Uncrustify.format( config: config, file: code, language: Uncrustify.Language( rawValue: self.language ) ?? .c )

                if text.isEmpty == false
                {
                    self.codeController.text = text
                }
            }
            catch
            {
                self.presentError( error )
            }
        }
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
        if let url = self.configCacheFile
        {
            try? self.configController.config.data.write( to: url )
        }

        if let url = self.codeCacheFile, let data = self.codeController.text.data( using: .utf8 )
        {
            try? data.write( to: url )
        }
    }

    private func restoreState()
    {
        if let url = self.configCacheFile, let config = Config( url: url )
        {
            self.configController.config = config
        }
        else if let config = try? Uncrustify.defaultConfig()
        {
            self.configController.config = Config( text: config )
        }

        if let url = self.codeCacheFile, let text = try? self.readFile( url: url )
        {
            self.codeController.text = text
        }
        else if let url = Bundle.main.url( forResource: "CFBase", withExtension: "txt" ), let text = try? self.readFile( url: url )
        {
            self.codeController.text = text
        }
    }

    @IBAction
    private func chooseTheme( _ sender: Any? )
    {
        self.codeController.chooseTheme( sender )
    }

    @IBAction
    private func toggleSorting( _ sender: Any? )
    {
        self.configController.sortValues = self.configController.sortValues == false
    }

    public func menuWillOpen( _ menu: NSMenu )
    {
        guard menu == self.optionsMenu
        else
        {
            return
        }

        menu.items.forEach
        {
            if $0.action == #selector( self.toggleSorting( _: ) )
            {
                $0.state = self.configController.sortValues ? .on : .off
            }
        }
    }

    @IBAction
    private func showTags( _ sender: Any? )
    {
        guard let view = sender as? NSView, let event = NSApp.currentEvent
        else
        {
            return
        }

        let names: [ String ] = self.configController.config.values.compactMap
        {
            switch $0
            {
                case .left:               return nil
                case .right( let value ): return value.name
            }
        }

        let tags: Set< String > = Set(
            names.compactMap
            {
                let s = $0 as NSString
                let r = s.range( of: "_" )

                if r.location != NSNotFound
                {
                    return s.substring( to: r.location + 1 )
                }

                return $0
            }
        )

        let menu = NSMenu()

        tags.sorted().forEach
        {
            let title = $0.hasSuffix( "_" ) ? String( $0.dropLast( 1 ) ) : $0

            menu.addItem( withTitle: title.capitalized, action: #selector( self.selectTag( _: ) ), representedObject: $0, isOn: self.configController.selectedTag == $0 )
        }

        NSMenu.popUpContextMenu( menu, with: event, for: view )
    }

    @IBAction
    private func showLanguages( _ sender: Any? )
    {
        guard let view = sender as? NSView, let event = NSApp.currentEvent
        else
        {
            return
        }

        let menu = NSMenu()

        menu.addItem( withTitle: "C",           action: #selector( self.selectLanguage( _: ) ), representedObject: "_c_",   isOn: self.configController.selectedLanguage == "_c_" )
        menu.addItem( withTitle: "C++",         action: #selector( self.selectLanguage( _: ) ), representedObject: "_cpp_", isOn: self.configController.selectedLanguage == "_cpp_" )
        menu.addItem( withTitle: "Objective-C", action: #selector( self.selectLanguage( _: ) ), representedObject: "_oc_",  isOn: self.configController.selectedLanguage == "_oc_" )

        NSMenu.popUpContextMenu( menu, with: event, for: view )
    }

    @IBAction
    private func selectTag( _ sender: Any? )
    {
        guard let item = sender as? NSMenuItem, let tag = item.representedObject as? String
        else
        {
            return
        }

        self.configController.selectedTag = self.configController.selectedTag == tag ? nil : tag
    }

    @IBAction
    private func selectLanguage( _ sender: Any? )
    {
        guard let item = sender as? NSMenuItem, let lang = item.representedObject as? String
        else
        {
            return
        }

        self.configController.selectedLanguage = self.configController.selectedLanguage == lang ? nil : lang
    }
}
