//
//  Preferences+Helper.swift
//  Drop2Download
//
//  Created by Diatoming on 6/28/20.
//  Copyright © 2020 diatoming. All rights reserved.
//

import Foundation
import Cocoa

/// How to:
/// 1: create preferences storyboard
/// 2: add window controller and drag a tabView view controller to replace the content view controller, then set to PreferencesTabViewController;
/// set tab style to Toolbar
/// 3: set tabView's delegate, set tabView to PreferencesTabView
/// 4: make sure window's Controls' resize checkbox is unchecked to make window unable to resize

/// Subclass of tab view controller used as App preferences window - auto resize and animate window frame when tab selection changed
/// Two requirements to make this work:
// 1: To make the window frame change, make sure the tabItem has a fixed width and height, make sure the views not auto resize in Interface Builder
// 2: Make sure set the tabView delegate to PreferencesTabViewController in Interface Builder
open class PreferencesTabViewController: NSTabViewController {
    
    private var viewSize = [NSView: NSSize]()
    
    // MARK: - cache view sizes
    override open func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        
        super.tabView(tabView, willSelect: tabViewItem)
        if let newView = tabViewItem?.view {
            let newSize = newView.frame.size // size from storyboard constraints
            viewSize[newView] = viewSize[newView] ?? newSize
        }
    }
    
    // MARK: auto resize and animate window frame
    override open func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        resizeWindow(with: tabViewItem)
    }
    
    public func resizeWindow(with tabViewItem: NSTabViewItem?) {
        if let newView = tabViewItem?.view,
            let window = self.view.window,
            let contentSize = viewSize[newView] {
            
            let newWindowSize = window.frameRect(forContentRect: NSRect(origin: CGPoint.zero, size: contentSize)).size
            
            var frame = window.frame
            frame.origin.y += frame.size.height
            frame.origin.y -= newWindowSize.height
            frame.size = newWindowSize
            
            window.setFrame(frame, display:true, animate:true)
        }
    }
}

/// PreferencesTabView: automatically resize window size after view moved to window; need to make sure tabView has PreferencesViewController as its deletegate
final class PreferencesTabView: NSTabView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let vc = self.delegate as? PreferencesTabViewController {
            vc.resizeWindow(with: self.tabViewItems.first)
        }
    }
}
