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

import Foundation

public class ConfigValue: NSObject
{
    @objc public private( set ) dynamic var name:      String
    @objc public private( set ) dynamic var value:     String
    @objc public private( set ) dynamic var valueHint: String?
    @objc public private( set ) dynamic var comments:  [ String ]

    public init( name: String, value: String, valueHint: String, comments: [ String ] )
    {
        self.name      = name
        self.value     = value
        self.valueHint = valueHint
        self.comments  = comments
    }

    public init( name: String, value: String, comments: [ String ] )
    {
        self.name     = name
        self.value    = value
        self.comments = comments
    }

    public override var description: String
    {
        "\( super.description ): \( self.name )"
    }

    public var data: Data?
    {
        var lines = self.comments

        if let hint = self.valueHint
        {
            lines.append( "\( self.name ) = \( self.value ) # \( hint )" )
        }
        else
        {
            lines.append( "\( self.name ) = \( self.value )" )
        }

        lines.append( "" )

        return lines.joined( separator: "\n" ).data( using: .utf8 )
    }
}
