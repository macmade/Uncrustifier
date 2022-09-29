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

public class Uncrustify
{
    public enum Language: Int
    {
        case c
        case cpp
        case cs
        case java
        case objc
        case objcpp
    }

    public class func defaultConfig() throws -> String
    {
        try self.run( arguments: [ "--update-config-with-doc" ] )
    }

    public class func format( config: URL, file: URL, language: Language ) throws -> String
    {
        let lang =
        {
            switch language
            {
                case .c:      return "C"
                case .cpp:    return "CPP"
                case .cs:     return "CS"
                case .java:   return "JAVA"
                case .objc:   return "OC"
                case .objcpp: return "OC+"
            }
        }()

        return try self.run( arguments: [ "-c", config.path, "-f", file.path, "-l", lang ] )
    }

    public class func run( arguments: [ String ] ) throws -> String
    {
        let process = try Uncrustify( arguments: arguments )

        process.run()

        return String( data: process.standardOutput, encoding: .utf8 ) ?? ""
    }

    private class func executableURL() -> URL?
    {
        Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent( "uncrustify" )
    }

    private var task:              Process
    private var pipeOut:           Pipe
    private var pipeErr:           Pipe
    private var standardOutput:    Data
    private var standardError:     Data
    private var terminationStatus: Int32?

    private init( arguments: [ String ] ) throws
    {
        guard let exec = Uncrustify.executableURL()
        else
        {
            throw NSError( title: "Cannot Find Uncrustify", message: "The Uncrustify executable was not found at its expected location in the application's bundle." )
        }

        self.pipeOut = Pipe()
        self.pipeErr = Pipe()
        self.task    = Process()

        self.task.launchPath     = exec.path
        self.task.arguments      = arguments
        self.task.standardOutput = self.pipeOut
        self.task.standardError  = self.pipeErr

        self.standardOutput = Data()
        self.standardError  = Data()

        NotificationCenter.default.addObserver( self, selector: #selector( self.dataAvailableForStandardOutput( _: ) ), name: NSNotification.Name.NSFileHandleDataAvailable, object: self.pipeOut.fileHandleForReading )
        NotificationCenter.default.addObserver( self, selector: #selector( self.dataAvailableForStandardError( _: )  ), name: NSNotification.Name.NSFileHandleDataAvailable, object: self.pipeErr.fileHandleForReading )

        self.pipeOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
        self.pipeErr.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    private func run()
    {
        self.task.launch()
        self.task.waitUntilExit()

        self.terminationStatus = self.task.terminationStatus

        #if DEBUG
            if let err = String( data: self.standardError, encoding: .utf8 )?.trimmingCharacters( in: .whitespacesAndNewlines )
            {
                print( err )
            }
        #endif
    }

    @objc
    private func dataAvailableForStandardOutput( _ notification: Notification )
    {
        guard let handle = notification.object as? FileHandle?,
              let data   = handle?.availableData
        else
        {
            return
        }

        self.standardOutput.append( data )
        handle?.waitForDataInBackgroundAndNotify()
    }

    @objc
    private func dataAvailableForStandardError( _ notification: Notification )
    {
        guard let handle = notification.object as? FileHandle?,
              let data = handle?.availableData
        else
        {
            return
        }

        self.standardError.append( data )
        handle?.waitForDataInBackgroundAndNotify()
    }
}
