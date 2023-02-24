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

@objc
public extension NSApplication
{
    @IBAction
    func invertAppearance( _ sender: Any? )
    {
        if self.effectiveAppearance.name == .aqua
        {
            self.appearance = NSAppearance( named: .darkAqua )
        }
        else if self.effectiveAppearance.name == .darkAqua
        {
            self.appearance = NSAppearance( named: .aqua )
        }
        else if self.effectiveAppearance.name == .accessibilityHighContrastAqua
        {
            self.appearance = NSAppearance( named: .accessibilityHighContrastDarkAqua )
        }
        else if self.effectiveAppearance.name == .accessibilityHighContrastDarkAqua
        {
            self.appearance = NSAppearance( named: .accessibilityHighContrastAqua )
        }
        else if self.effectiveAppearance.name == .vibrantLight
        {
            self.appearance = NSAppearance( named: .vibrantDark )
        }
        else if self.effectiveAppearance.name == .vibrantDark
        {
            self.appearance = NSAppearance( named: .vibrantLight )
        }
        else if self.effectiveAppearance.name == .accessibilityHighContrastVibrantLight
        {
            self.appearance = NSAppearance( named: .accessibilityHighContrastVibrantDark )
        }
        else if self.effectiveAppearance.name == .accessibilityHighContrastVibrantDark
        {
            self.appearance = NSAppearance( named: .accessibilityHighContrastVibrantLight )
        }
    }
}
