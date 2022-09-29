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

public class ConfigViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout
{
    @objc public dynamic var config = Config()
    {
        didSet
        {
            self.controllers = self.config.values.compactMap
            {
                switch $0
                {
                    case .left:               return nil
                    case .right( let value ): return ConfigValueViewController( value: value )
                }
            }
        }
    }

    @objc private dynamic var controllers: [ ConfigValueViewController ] = []

    @IBOutlet private var collectionView: NSCollectionView!

    public init()
    {
        super.init( nibName: nil, bundle: nil )
    }

    required init?( coder: NSCoder )
    {
        nil
    }

    public override var nibName: NSNib.Name?
    {
        "ConfigViewController"
    }

    public override func viewDidLoad()
    {
        super.viewDidLoad()
    }

    public func collectionView( _ collectionView: NSCollectionView, numberOfItemsInSection section: Int ) -> Int
    {
        self.controllers.count
    }

    public func collectionView( _ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath ) -> NSCollectionViewItem
    {
        let item = collectionView.makeItem( withIdentifier: NSUserInterfaceItemIdentifier( "ConfigViewItem" ), for: indexPath )

        if let item = item as? ConfigViewItem
        {
            item.controller = self.controllers[ indexPath.item ]
        }

        item.view.layoutSubtreeIfNeeded()

        return item
    }

    public func collectionView( _ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath ) -> NSSize
    {
        let controller        = self.controllers[ indexPath.item ]
        var frame             = controller.view.frame
        frame.size.width      = self.collectionView.frame.size.width
        controller.view.frame = frame

        controller.view.layoutSubtreeIfNeeded()

        return NSSize( width: controller.view.frame.size.width, height: controller.view.frame.size.height )
    }
}
