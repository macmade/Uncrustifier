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

    @objc private dynamic var configController    = ConfigViewController()
    @objc private dynamic var codeController      = TextViewController()
    @objc private dynamic var formatUsingAllRules = false
    @objc private dynamic var currentExample:       ConfigValue?
    {
        willSet
        {
            if self.currentExample == nil
            {
                self.savedCode     = self.codeController.text
                self.savedLanguage = self.language
            }
        }
    }

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

    private var cacheDirectory:       URL?
    private var configCacheFile:      URL?
    private var codeCacheFile:        URL?
    private var windowObserver:       Any?
    private var valueChangedObserver: Any?
    private var loadExampleObserver:  Any?
    private var savedCode:            String?
    private var savedLanguage:        Int?

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

        self.valueChangedObserver = NotificationCenter.default.addObserver( forName: ConfigValue.valueChangedNotification, object: nil, queue: nil )
        {
            [ weak self ] _ in

            guard let self = self
            else
            {
                return
            }

            if self.configController.autoFormat
            {
                DispatchQueue.main.async
                {
                    self.format( nil )
                }
            }
        }

        self.loadExampleObserver = NotificationCenter.default.addObserver( forName: ConfigValueViewController.loadExampleNotification, object: nil, queue: nil )
        {
            [ weak self ] in

            guard let self = self
            else
            {
                return
            }

            if let controller = $0.object as? ConfigValueViewController,
               let example    = controller.value.example
            {
                self.currentExample      = controller.value
                self.codeController.text = example
                self.language            = Uncrustify.Language.objcpp.rawValue

                DispatchQueue.main.async
                {
                    self.format( nil )
                }
            }
        }

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
            [ weak self ] _ in

            self?.resetCurrentExample( nil )
            self?.saveState()
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
        guard let window = self.window
        else
        {
            return
        }

        let alert             = NSAlert()
        alert.messageText     = "Reload Default Configuration"
        alert.informativeText = "Are you sure you want to reload the default configuration?"

        alert.addButton( withTitle: "Reload" )
        alert.addButton( withTitle: "Cancel" )

        alert.beginSheetModal( for: window )
        {
            if $0 != .alertFirstButtonReturn
            {
                return
            }

            guard let config = try? Uncrustify.defaultConfig()
            else
            {
                self.displayError( message: "Cannot load the default Uncrustify configuration." )

                return
            }

            self.configController.config = Config( text: config )
        }
    }

    @IBAction
    private func reloadExampleCode( _ sender: Any? )
    {
        guard let window = self.window
        else
        {
            return
        }

        let alert             = NSAlert()
        alert.messageText     = "Reload Example Code"
        alert.informativeText = "Are you sure you want to reload the example code?"

        alert.addButton( withTitle: "Reload" )
        alert.addButton( withTitle: "Cancel" )

        alert.beginSheetModal( for: window )
        {
            if $0 != .alertFirstButtonReturn
            {
                return
            }

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
    }

    @IBAction
    private func format( _ sender: Any? )
    {
        self.saveState()

        DispatchQueue.main.async
        {
            guard var config = self.configCacheFile,
                  let code   = self.codeCacheFile
            else
            {
                self.displayError( title: "No Caches Directory", message: "The application's caches directory does not exists, or failed to be created." )

                return
            }

            do
            {
                if let example = self.currentExample, self.formatUsingAllRules == false
                {
                    config = URL( fileURLWithPath: NSTemporaryDirectory() ).appending( path: UUID().uuidString )

                    try example.data?.write( to: config )
                }

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

    @IBAction
    private func toggleAutoFormat( _ sender: Any? )
    {
        self.configController.autoFormat = self.configController.autoFormat == false
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
            else if $0.action == #selector( self.toggleAutoFormat( _: ) )
            {
                $0.state = self.configController.autoFormat ? .on : .off
            }
        }
    }

    @IBAction
    private func showEdited( _ sender: Any? )
    {
        guard let view = sender as? NSView, let event = NSApp.currentEvent
        else
        {
            return
        }

        let menu = NSMenu()

        menu.addItem( withTitle: "Show Only Edited",     action: #selector( self.toggleShowEdited( _: ) ), representedObject: NSNumber( booleanLiteral: true ),  isOn: self.configController.showEdited == true )
        menu.addItem( withTitle: "Show Only Non Edited", action: #selector( self.toggleShowEdited( _: ) ), representedObject: NSNumber( booleanLiteral: false ), isOn: self.configController.showEdited == false )

        NSMenu.popUpContextMenu( menu, with: event, for: view )
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
    private func toggleShowEdited( _ sender: Any? )
    {
        guard let item = sender as? NSMenuItem, let show = item.representedObject as? NSNumber
        else
        {
            return
        }

        if let current = self.configController.showEdited, current.boolValue == show.boolValue
        {
            self.configController.showEdited = nil
        }
        else
        {
            self.configController.showEdited = show
        }
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

    @IBAction
    private func resetCurrentExample( _ sender: Any? )
    {
        if let code = self.savedCode
        {
            self.codeController.text = code
        }

        if let savedLanguage = self.savedLanguage
        {
            self.language = savedLanguage
        }

        self.savedCode      = nil
        self.savedLanguage  = nil
        self.currentExample = nil
    }

    @IBAction
    public func reloadExamples( _ sender: Any? )
    {
        self.configController.config.values.forEach
        {
            switch $0
            {
                case .left:               return
                case .right( let value ): value.loadExample()
            }
        }
    }
}
