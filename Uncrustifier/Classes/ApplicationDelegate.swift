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
import GitHubUpdates

@main
public class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    private let mainWindowController    = MainWindowController()
    private let aboutWindowController   = AboutWindowController()
    private let creditsWindowController = CreditsWindowController()

    @IBOutlet private var updater: GitHubUpdater!

    public func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.mainWindowController.window?.center()
        self.mainWindowController.window?.makeKeyAndOrderFront( nil )

        DispatchQueue.main.asyncAfter( deadline: .now() + .seconds( 2 ) )
        {
            self.updater.checkForUpdatesInBackground()
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed( _ sender: NSApplication ) -> Bool
    {
        true
    }

    @IBAction
    public func showAboutWindow( _ sender: Any? )
    {
        if self.aboutWindowController.window?.isVisible == false
        {
            self.aboutWindowController.window?.center()
        }

        self.aboutWindowController.window?.makeKeyAndOrderFront( sender )
    }

    @IBAction
    public func showCreditsWindow( _ sender: Any? )
    {
        if self.creditsWindowController.window?.isVisible == false
        {
            self.creditsWindowController.window?.center()
        }

        self.creditsWindowController.window?.makeKeyAndOrderFront( sender )
    }
}
