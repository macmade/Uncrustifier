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

import Foundation

@objc
public class Config: NSObject
{
    public private( set ) dynamic var values: [ Either< String, ConfigValue > ] = []

    public override init()
    {}

    public init( text: String )
    {
        super.init()
        self.parse( text: text )
    }

    public convenience init?( url: URL )
    {
        guard let data = try? Data( contentsOf: url ),
              let text = String( data: data, encoding: .utf8 )
        else
        {
            return nil
        }

        self.init( text: text )
    }

    public var data: Data
    {
        self.values.reduce( into: Data() )
        {
            switch $1
            {
                case .left( let comment ):

                    if let data = comment.appending( "\n" ).data( using: .utf8 )
                    {
                        $0.append( data )
                    }

                case .right( let value ):

                    if let data = value.data
                    {
                        $0.append( data )
                    }
            }
        }
    }

    private func parse( text: String )
    {
        var comments: [ String ] = []

        text.components( separatedBy: .newlines ).forEach
        {
            let line = $0.trimmingCharacters( in: .whitespaces )

            guard let first = line.first
            else
            {
                comments.forEach
                {
                    self.values.append( .left( $0 ) )
                }

                comments = []

                self.values.append( .left( "" ) )

                return
            }

            if first == "#"
            {
                comments.append( String( line.trimmingCharacters( in: .whitespaces ) ) )

                return
            }

            let parts = line.split( separator: "=", maxSplits: 1 )

            if parts.count != 2
            {
                comments.forEach
                {
                    self.values.append( .left( $0 ) )
                }

                comments = []

                self.values.append( .left( line ) )

                return
            }

            let name  = String( parts[ 0 ] ).trimmingCharacters( in: .whitespaces )
            let right = String( parts[ 1 ] ).trimmingCharacters( in: .whitespaces )

            if let pos = right.lastIndex( of: "#" )
            {
                let value   = String( right[ right.startIndex ..< pos ] ).trimmingCharacters( in: .whitespaces )
                let comment = String( right[ pos ..< right.endIndex ].dropFirst( 1 ) ).trimmingCharacters( in: .whitespaces )

                self.values.append( .right( ConfigValue( name: name, value: value, valueHint: comment, comments: comments ) ) )
            }
            else
            {
                self.values.append( .right( ConfigValue( name: name, value: right, comments: comments ) ) )
            }

            comments = []
        }
    }
}
