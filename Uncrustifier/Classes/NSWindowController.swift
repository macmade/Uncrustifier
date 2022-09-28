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
import UniformTypeIdentifiers

public extension NSWindowController
{
    func chooseFile( completion: @escaping ( URL? ) -> Void )
    {
        let panel                           = NSOpenPanel()
        panel.canChooseFiles                = true
        panel.canChooseDirectories          = false
        panel.canDownloadUbiquitousContents = true
        panel.canCreateDirectories          = false

        self.displayPanel( panel )
        {
            completion( $0 == .OK ? panel.url : nil )
        }
    }

    func saveFile( data: Data, name: String?, extension ext: String? )
    {
        let panel                  = NSSavePanel()
        panel.canCreateDirectories = true

        if let ext = ext, let type = UTType( filenameExtension: ext )
        {
            panel.nameFieldStringValue = name ?? ""
            panel.allowedContentTypes  = [ type ]
            panel.allowsOtherFileTypes = false
        }
        else
        {
            if let name = name, let ext = ext
            {
                panel.nameFieldStringValue = "\( name ).\( ext )"
            }
            else if let name = name
            {
                panel.nameFieldStringValue = name
            }

            panel.allowsOtherFileTypes = true
        }

        self.displayPanel( panel )
        {
            guard $0 == .OK, let url = panel.url
            else
            {
                return
            }

            do
            {
                try data.write( to: url )
            }
            catch
            {
                self.displayError( error )
            }
        }
    }

    func displayPanel( _ panel: NSSavePanel, completion: @escaping ( NSApplication.ModalResponse ) -> Void )
    {
        if let window = self.window
        {
            panel.beginSheetModal( for: window, completionHandler: completion )
        }
        else
        {
            completion( panel.runModal() )
        }
    }

    func displayError( message: String )
    {
        self.displayError( title: "Error", message: message )
    }

    func displayError( title: String, message: String )
    {
        let alert             = NSAlert()
        alert.messageText     = title
        alert.informativeText = message

        alert.addButton( withTitle: "OK" )

        self.displayAlert( alert )
    }

    func displayError( _ error: Error )
    {
        self.displayAlert( NSAlert( error: error ) )
    }

    func displayAlert( _ alert: NSAlert )
    {
        if let window = self.window
        {
            alert.beginSheetModal( for: window )
        }
        else
        {
            alert.runModal()
        }
    }
}
