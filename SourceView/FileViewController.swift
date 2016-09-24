//
//  FileViewController.swift
//  SourceView
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/4/6.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 View controller object to host the UI for file information
 */

import Cocoa

@objc(FileViewController)
class FileViewController: NSViewController {
    
    var url: URL?
    
    @IBOutlet fileprivate var fileIcon: NSImageView!
    @IBOutlet fileprivate var fileName: NSTextField!
    @IBOutlet fileprivate var fileSize: NSTextField!
    @IBOutlet fileprivate var modDate: NSTextField!
    @IBOutlet fileprivate var creationDate: NSTextField!
    @IBOutlet fileprivate var fileKindString: NSTextField!
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	awakeFromNib
    // -------------------------------------------------------------------------------
    override func awakeFromNib() {
        // listen for changes in the url for this view
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
    //	observeValueForKeyPath:ofObject:change:context
    //
    //	Listen for changes in the file url.
    // -------------------------------------------------------------------------------
    override func observeValue(forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?)
    {
        if let url = self.url {
             let path = url.path
            // name
            self.fileName.stringValue = FileManager.default.displayName(atPath: path)
            
            // icon
            let iconImage = NSWorkspace.shared().icon(forFile: path)
            iconImage.size = NSMakeSize(64, 64)
            self.fileIcon.image = iconImage
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: path)
                // file size
                let theFileSize = attr[FileAttributeKey.size] as! NSNumber
                self.fileSize.stringValue = "\(theFileSize.stringValue) KB on disk"
                
                // creation date
                let fileCreationDate = attr[FileAttributeKey.creationDate] as! Date
                self.creationDate.stringValue = fileCreationDate.description
                
                // mod date
                let fileModDate = attr[FileAttributeKey.modificationDate] as! Date
                self.modDate.stringValue = fileModDate.description
            } catch _ {
            }
            
            // kind string
            var umKindStr: Unmanaged<CFString>? = nil
            LSCopyKindStringForURL(url as CFURL!, &umKindStr)
            if umKindStr != nil {
                let kindStr: CFString = umKindStr!.takeRetainedValue()
                self.fileKindString.stringValue = kindStr as String
            }
        } else {
            self.fileName.stringValue = ""
            self.fileIcon.image = nil
            self.fileSize.stringValue = ""
            self.creationDate.stringValue = ""
            self.modDate.stringValue = ""
            self.fileKindString.stringValue = ""
        }
    }
    
}
