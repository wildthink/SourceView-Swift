//
//  IconViewController.swift
//  SourceView
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/4/5.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 View controller object to host the icon collection view.
 */

import Cocoa

// notification for indicating file system content has been received
let kReceivedContentNotification = "ReceivedContentNotification"

// key values for the icon view dictionary
private let KEY_NAME = "name"
private let KEY_ICON = "icon"

// notification for indicating file system content has been received

@objc(IconViewBox)
class IconViewBox: NSBox {
    override func hitTest(_ aPoint: NSPoint) -> NSView? {
        // don't allow any mouse clicks for subviews in this NSBox
        return nil
    }
}


//MARK: -

@objc(IconViewController)
class IconViewController: NSViewController {
    
    dynamic var url: URL?
    
    @IBOutlet fileprivate var iconArrayController: NSArrayController!
    dynamic var icons: [Any] = []
    
    
    // -------------------------------------------------------------------------------
    //	awakeFromNib
    // -------------------------------------------------------------------------------
    override func awakeFromNib() {
        // listen for changes in the url for this view
        //###Neither the receiver, nor anObserver, are retained.
        self.addObserver(self,
            forKeyPath: "url",
            options: [.new, .old],
            context: nil)
    }
    
    // -------------------------------------------------------------------------------
    //	dealloc
    // -------------------------------------------------------------------------------
    deinit {
        self.removeObserver(self, forKeyPath: "url")
    }
    
    // -------------------------------------------------------------------------------
    //	updateIcons:iconArray
    //
    //	The incoming object is the NSArray of file system objects to display.
    //-------------------------------------------------------------------------------
    fileprivate func updateIcons(_ iconArray: [Any]) {
        self.icons = iconArray
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kReceivedContentNotification), object: nil)
    }
    
    // -------------------------------------------------------------------------------
    //	gatherContents:inObject
    //
    //	Gathering the contents and their icons could be expensive.
    //	This method is being called on a separate thread to avoid blocking the UI.
    // -------------------------------------------------------------------------------
    fileprivate func gatherContents(_ inObject: URL) {
        var contentArray: [Any] = []
        autoreleasepool {
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: self.url!,
                    includingPropertiesForKeys: [],
                    options: [])
                for element in fileURLs {
                    let elementIcon = NSWorkspace.shared().icon(forFile: element.path)
                    
                    // only allow visible objects
                    var hiddenFlag: AnyObject? = nil
                    try (element as NSURL).getResourceValue(&hiddenFlag, forKey: URLResourceKey.isHiddenKey)
                    if !(hiddenFlag as! Bool) {
                        var elementNameStr: AnyObject? = nil
                        try (element as NSURL).getResourceValue(&elementNameStr, forKey: URLResourceKey.localizedNameKey)
                        // file system object is visible so add to our array
                        contentArray.append([
                            "icon": elementIcon,
                            "name": elementNameStr as! String
                            ])
                    }
                }
            } catch _ {}
            
            // call back on the main thread to update the icons in our view
            DispatchQueue.main.sync {
                self.updateIcons(contentArray)
            }
        }
    }
    
    // -------------------------------------------------------------------------------
    //	observeValueForKeyPath:ofObject:change:context
    //
    //	Listen for changes in the file url.
    //	Given a url, obtain its contents and add only the invisible items to the collection.
    // -------------------------------------------------------------------------------
    override func observeValue(forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?)
    {
        // build our directory contents on a separate thread,
        // some portions are from disk which could get expensive depending on the size
        //
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            self.gatherContents(self.url!)
        }
    }
    
}
