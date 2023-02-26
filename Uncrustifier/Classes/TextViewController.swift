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

public class TextViewController: NSViewController
{
    @IBOutlet private var textView: NSTextView!

    private var textStorage:            CodeAttributedString
    private var themeObserver:          NSKeyValueObservation?
    private var themeWindowController = ThemeWindowController()

    @objc public dynamic var text: String
    {
        get
        {
            self.textStorage.string
        }

        set( value )
        {
            self.textStorage.replaceCharacters( in: NSRange( location: 0, length: self.textStorage.string.count ), with: value )
        }
    }

    public init()
    {
        if let highlightr = Highlightr()
        {
            self.textStorage = CodeAttributedString( highlightr: highlightr )
        }
        else
        {
            self.textStorage = CodeAttributedString()
        }

        super.init( nibName: nil, bundle: nil )
    }

    required init?( coder: NSCoder )
    {
        nil
    }

    public override var nibName: NSNib.Name?
    {
        "TextViewController"
    }

    public override func viewDidLoad()
    {
        super.viewDidLoad()

        if let theme = UserDefaults.standard.string( forKey: "theme" )
        {
            self.textStorage.highlightr.setTheme( to: theme )
        }
        else
        {
            self.textStorage.highlightr.setTheme( to: "vs2015" )
        }

        self.textView.font                               = NSFont.monospacedSystemFont( ofSize: 12, weight: .regular )
        self.textView.textContainerInset                 = NSSize( width: 10, height: 10 )
        self.textView.maxSize                            = NSSize( width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude )
        self.textView.isHorizontallyResizable            = true
        self.textView.textContainer?.widthTracksTextView = false
        self.textView.textContainer?.containerSize       = NSSize( width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude )

        if let layoutManager = self.textView.textContainer?.layoutManager
        {
            if let storage = layoutManager.textStorage
            {
                storage.removeLayoutManager( layoutManager )
            }

            self.textStorage.addLayoutManager( layoutManager )
        }

        self.themeObserver = self.themeWindowController.observe( \.theme )
        {
            [ weak self ] _, _ in

            guard let self = self
            else
            {
                return
            }

            self.textStorage.highlightr.setTheme( to: self.themeWindowController.theme )
            UserDefaults.standard.set( self.themeWindowController.theme, forKey: "theme" )
        }
    }

    public func setTheme( _ theme: String )
    {
        self.textStorage.highlightr.setTheme( to: theme )
    }

    public func setLanguage( _ language: Uncrustify.Language )
    {
        switch language
        {
            case .c:      self.textStorage.language = "c"
            case .cpp:    self.textStorage.language = "cpp"
            case .cs:     self.textStorage.language = "csharp"
            case .java:   self.textStorage.language = "java"
            case .objc:   self.textStorage.language = "objectivec"
            case .objcpp: self.textStorage.language = "objectivec"
        }
    }

    public func setAsFirstResponder()
    {
        self.view.window?.makeFirstResponder( self.textView )
    }

    @IBAction
    public func chooseTheme( _ sender: Any? )
    {
        if self.themeWindowController.window?.isVisible == false
        {
            self.themeWindowController.window?.center()
        }

        self.themeWindowController.window?.makeKeyAndOrderFront( sender )
    }
}
