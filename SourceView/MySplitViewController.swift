//
//  MySplitViewController.swift
//  SourceView
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/10/24.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 View controller managing our split view interface
 */
import Cocoa

@objc(MySplitViewController)
class MySplitViewController: NSSplitViewController {
    
    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []
    
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	viewDidAppear
    // -------------------------------------------------------------------------------
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Note: we keep the left split view item from growing as the window grows by setting its holding priority to 200, and the right to 199.
        // The view with the lowest priority will be the first to take on additional width if the split view grows or shrinks.
        //
        
        // listen for selection changes from the NSOutlineView inside MyOutlineViewController
        // note: we start observing after our outline view is populated so we don't receive unnecessary notifications at startup
        //
        self.outlineViewController.treeController.addObserver(self,
            forKeyPath: "selectedObjects",
            options: .New,
            context: nil)
    }
    
    deinit {
        // done listening for tree controller's selection
        self.outlineViewController.treeController.removeObserver(self, forKeyPath: "selectedObjects")
    }
    
    
    //MARK: - Detail View Controller Management
    
    // -------------------------------------------------------------------------------
    //	outlineViewController
    // -------------------------------------------------------------------------------
    private var outlineViewController: MyOutlineViewController {
        let leftSplitViewItem = self.splitViewItems[0]
        return leftSplitViewItem.viewController as! MyOutlineViewController
    }
    
    // -------------------------------------------------------------------------------
    //	detailViewController
    // -------------------------------------------------------------------------------
    private var detailViewController: NSViewController {
        let rightSplitViewItem = self.splitViewItems[1]
        return rightSplitViewItem.viewController
    }
    
    // -------------------------------------------------------------------------------
    //	hasChildViewController
    // -------------------------------------------------------------------------------
    private var hasChildViewController: Bool {
        return !self.detailViewController.childViewControllers.isEmpty
    }
    
    // -------------------------------------------------------------------------------
    //	embedChildViewController:childViewController
    // -------------------------------------------------------------------------------
    private func embedChildViewController(childViewController: NSViewController) {
        // to embed a new child view controller we have to add it and its view, then setup auto layout contraints
        //
        let currentDetailVC = self.detailViewController
        currentDetailVC.addChildViewController(childViewController)
        currentDetailVC.view.addSubview(childViewController.view)
        
        let views = ["targetView" : childViewController.view]
        horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[targetView]|",
            options: [],
            metrics: nil,
            views: views)
        verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[targetView]|",
            options: [],
            metrics: nil,
            views: views)
        
        NSLayoutConstraint.activateConstraints(self.horizontalConstraints)
        NSLayoutConstraint.activateConstraints(self.verticalConstraints)
    }
    
    // -------------------------------------------------------------------------------
    //	observeValueForKeyPath:ofObject:change:context
    // -------------------------------------------------------------------------------
    override func observeValueForKeyPath(keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>)
    {
        if keyPath == "selectedObjects" {
            let currentDetailVC = self.detailViewController
            
            let treeController = object as! NSTreeController
            
            // let the outline view controller handle the selection (helps us decide which detail view to use)
            if let vcForDetail = self.outlineViewController.viewControllerForSelection(treeController.selectedNodes) {
                if self.hasChildViewController && currentDetailVC.childViewControllers[0] != vcForDetail {
                    // the incoming child view controller is different from the one we currently have,
                    // remove the old one and add the new one
                    //
                    currentDetailVC.removeChildViewControllerAtIndex(0)
                    self.detailViewController.view.subviews[0].removeFromSuperview()
                    
                    self.embedChildViewController(vcForDetail)
                } else {
                    if !self.hasChildViewController {
                        // we don't have a child view controller so embed the new one
                        self.embedChildViewController(vcForDetail)
                    }
                }
            } else {
                // we don't have a child view controller to embed (no selection), so remove current child view controller
                if self.hasChildViewController {
                    currentDetailVC.removeChildViewControllerAtIndex(0)
                    self.detailViewController.view.subviews[0].removeFromSuperview()
                }
            }
        }
    }
    
}