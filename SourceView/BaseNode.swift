//
//  BaseNode.swift
//  SourceView
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/3/29.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Generic multi-use node object used with NSOutlineView and NSTreeController.
 */

import Cocoa

@objc(BaseNode)
class BaseNode: NSObject, NSCoding, NSCopying {
    
    dynamic var nodeTitle: String
    dynamic var nodeIcon: NSImage?
    private var _children: [BaseNode] = []
    dynamic var urlString: String?
    dynamic var isLeaf: Bool = false	// is container by default
    
    // -------------------------------------------------------------------------------
    //	init
    // -------------------------------------------------------------------------------
    required override init() {
        self.nodeTitle = "BaseNode Untitled"
        super.init()
    }
    
    // -------------------------------------------------------------------------------
    //	initLeaf
    // -------------------------------------------------------------------------------
    @objc(initLeaf)
    convenience init(leaf: Void) {
        self.init()
        self.setLeaf(true)
    }
    
    // -------------------------------------------------------------------------------
    //	setLeaf:flag
    // -------------------------------------------------------------------------------
    private func setLeaf(flag: Bool) {
        self.isLeaf = flag
    }
    
    dynamic var children: [BaseNode] {
        get {
            if self.isLeaf {
                return [self]
            } else {
                return _children
            }
        }
        set {
            _children = newValue
        }
    }
    
    // -------------------------------------------------------------------------------
    //	isBookmark
    // -------------------------------------------------------------------------------
    var isBookmark: Bool {
        get {
            
            return self.urlString?.hasPrefix("http://") ?? false
        }
        
        // -------------------------------------------------------------------------------
        //	setIsBookmark:isBookmark
        // -------------------------------------------------------------------------------
        set {
            //### ignore
        }
    }
    
    // -------------------------------------------------------------------------------
    //	isDirectory
    // -------------------------------------------------------------------------------
    var isDirectory: Bool {
        get {
            var directory = false
            
            if let urlString = self.urlString {
                var isURLDirectory: AnyObject? = nil
                let url = NSURL(fileURLWithPath: urlString)
                
                _ = try? url.getResourceValue(&isURLDirectory, forKey: NSURLIsDirectoryKey)
                
                directory = (isURLDirectory as? NSNumber)?.boolValue ?? false
            }
            
            return directory
        }
        
        // -------------------------------------------------------------------------------
        //	setIsBookmark:isBookmark
        // -------------------------------------------------------------------------------
        //###ignore
    }
    
    // -------------------------------------------------------------------------------
    //	compare:aNode
    // -------------------------------------------------------------------------------
    func compare(aNode: BaseNode) -> NSComparisonResult {
        return (self.nodeTitle.lowercaseString as NSString).compare(aNode.nodeTitle.lowercaseString)
    }
    
    
    //MARK: - Drag and Drop
    
    // -------------------------------------------------------------------------------
    //	removeObjectFromChildren:obj
    //
    //	Recursive method which searches children and children of all sub-nodes
    //	to remove the given object.
    // -------------------------------------------------------------------------------
    func removeObjectFromChildren(obj: BaseNode) {
        // remove object from children or the children of any sub-nodes
        for (index, node) in self.children.enumerate() {
            if node === obj {
                self.children.removeAtIndex(index)
                return
            }
            
            if !node.isLeaf {
                node.removeObjectFromChildren(obj)
            }
        }
    }
    
    // -------------------------------------------------------------------------------
    //	descendants
    //
    //	Generates an array of all descendants.
    // -------------------------------------------------------------------------------
    var descendants: [BaseNode] {
        var descendants: [BaseNode] = []
        for node in self.children {
            descendants.append(node)
            
            if !node.isLeaf {
                descendants += node.descendants	// Recursive - will go down the chain to get all
            }
        }
        return descendants
    }
    
    // -------------------------------------------------------------------------------
    //	allChildLeafs:
    //
    //	Generates an array of all leafs in children and children of all sub-nodes.
    //	Useful for generating a list of leaf-only nodes.
    // -------------------------------------------------------------------------------
    var allChildLeafs: [BaseNode] {
        var childLeafs: [BaseNode] = []
        
        for node in self.children {
            if node.isLeaf {
                childLeafs.append(node)
            } else {
                childLeafs += node.allChildLeafs	// Recursive - will go down the chain to get all
            }
        }
        return childLeafs
    }
    
    // -------------------------------------------------------------------------------
    //	groupChildren
    //
    //	Returns only the children that are group nodes.
    // -------------------------------------------------------------------------------
    var groupChildren: [BaseNode] {
        var groupChildren: [BaseNode] = []
        
        for child in self.children {
            if !child.isLeaf {
                groupChildren.append(child)
            }
        }
        return groupChildren
    }
    
    // -------------------------------------------------------------------------------
    //	isDescendantOfOrOneOfNodes:nodes
    //
    //	Returns YES if self is contained anywhere inside the children or children of
    //	sub-nodes of the nodes contained inside the given array.
    // -------------------------------------------------------------------------------
    func isDescendantOfOrOneOfNodes(nodes: [BaseNode]) -> Bool {
        // returns YES if we are contained anywhere inside the array passed in, including inside sub-nodes
        for node in nodes {
            if node === self {
                return true		// we found ourselves
            }
            
            // check all the sub-nodes
            if !node.isLeaf {
                if self.isDescendantOfOrOneOfNodes(node.children) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // -------------------------------------------------------------------------------
    //	isDescendantOfNodes:nodes
    //
    //	Returns YES if any node in the array passed in is an ancestor of ours.
    // -------------------------------------------------------------------------------
    func isDescendantOfNodes(nodes: [BaseNode]) -> Bool {
        for node in nodes {
            // check all the sub-nodes
            if !node.isLeaf {
                if self.isDescendantOfOrOneOfNodes(node.children) {
                    return true
                }
            }
        }
        
        return false
    }
    
    
    //MARK: - Archiving And Copying Support
    
    // -------------------------------------------------------------------------------
    //	mutableKeys:
    //
    //	Override this method to maintain support for archiving and copying.
    // -------------------------------------------------------------------------------
    var mutableKeys: [String] {
        return ["nodeTitle",
            "isLeaf",		// isLeaf MUST come before children for initWithDictionary: to work
            "children",
            "nodeIcon",
            "urlString",
            "isBookmark"]
    }
    
    // -------------------------------------------------------------------------------
    //	initWithDictionary:dictionary
    // -------------------------------------------------------------------------------
    required convenience init(dictionary: [NSObject: AnyObject]) {
        self.init()
        for key in self.mutableKeys {
            if key == "children" {
                if dictionary["isLeaf"] as! Bool {
                    self.setLeaf(true)
                } else {
                    let dictChildren = dictionary[key] as! [[NSObject: AnyObject]]
                    var newChildren: [BaseNode] = []
                    
                    for node in dictChildren {
                        let newNode = self.dynamicType.init(dictionary: node)
                        newChildren.append(newNode)
                    }
                    self.children = newChildren
                }
            } else {
                self.setValue(dictionary[key], forKey: key)
            }
        }
    }
    
    // -------------------------------------------------------------------------------
    //	dictionaryRepresentation
    // -------------------------------------------------------------------------------
    func dictionaryRepresentation() -> [NSObject: AnyObject] {
        var dictionary: [NSObject: AnyObject] =  [:]
        
        for key in self.mutableKeys {
            // convert all children to dictionaries
            if key == "children" {
                if !self.isLeaf {
                    var dictChildren: [[NSObject: AnyObject]] = []
                    for node in self.children {
                        dictChildren.append(node.dictionaryRepresentation())
                    }
                    
                    dictionary[key] = dictChildren
                }
            } else if let value: AnyObject = self.valueForKey(key) {
                dictionary[key] = value
            }
        }
        return dictionary
    }
    
    // -------------------------------------------------------------------------------
    //	initWithCoder:coder
    // -------------------------------------------------------------------------------
    required convenience init?(coder: NSCoder) {
        self.init()
        for key in self.mutableKeys {
            self.setValue(coder.decodeObjectForKey(key), forKey: key)
        }
    }
    
    // -------------------------------------------------------------------------------
    //	encodeWithCoder:coder
    // -------------------------------------------------------------------------------
    func encodeWithCoder(coder: NSCoder) {
        for key in self.mutableKeys {
            coder.encodeObject(self.valueForKey(key), forKey: key)
        }
    }
    
    // -------------------------------------------------------------------------------
    //	copyWithZone:zone
    // -------------------------------------------------------------------------------
    func copyWithZone(zone: NSZone) -> AnyObject {
        let newNode = self.dynamicType.init() as BaseNode
        
        for key in self.mutableKeys {
            newNode.setValue(self.valueForKey(key), forKey: key)
        }
        
        return newNode
    }
    
    // -------------------------------------------------------------------------------
    //	setNilValueForKey:key
    //
    //	Override this for any non-object values
    // -------------------------------------------------------------------------------
    override func setNilValueForKey(key: String) {
        if key == "isLeaf" {
            self.isLeaf = false
        } else {
            super.setNilValueForKey(key)
        }
    }
    
}