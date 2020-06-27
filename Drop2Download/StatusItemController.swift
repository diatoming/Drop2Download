//
//  StatusItemController.swift
//  Mame Cast
//
//  Created by Diatoming on 1/28/20.
//  Copyright © 2020 diatoming.com. All rights reserved.
//

import Cocoa

// Add status item to menu bar
public class StatusItemController: NSObject, NSWindowDelegate, NSDraggingDestination {
    
    public typealias URLDropHandler = (URL) -> Void
    public lazy var onURLDropped: URLDropHandler? = nil
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    public init(image: NSImage) {
        super.init()
                
        if let button = self.statusItem.button {
            button.image = image
            button.image?.isTemplate = true
                        
            button.target = self
            button.action = #selector(self.statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        setupDragSupport()
    }
    
    private func setupDragSupport() {
        
        // Enable drag and drop if OS X >= 10.10
        if #available(macOS 10.10, *) {
            statusItem.button?.window?.delegate = self
            
            let types: [NSPasteboard.PasteboardType] = [
                .string, .URL, .fileURL, .tiff
            ]
            statusItem.button?.window?.registerForDraggedTypes(types)
        }
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        switch event.type {
        case .rightMouseUp:
            break
        case .leftMouseUp:
            break
        default: break
        }
    }
    
    func updateStatusItemImage() {
        
    }
    
    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
    
    // MARK: NSDraggingDestination
    
    public func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        
        guard let _ = self.onURLDropped else { return .generic }
        
        if let str = sender.draggingPasteboard.string(forType: .string),
            let _ = URL(string: str) {
            return .link
        }
        
//        print(sender.draggingPasteboard().propertyList(forType: NSURLPboardType))
//        print(sender.draggingPasteboard().propertyList(forType: NSURLPboardType) as? [String])
        
        if let urls = sender.draggingPasteboard.propertyList(forType: .URL) as? [String],
            urls.count > 0 {
            return .link
        }
        
        if let paths = sender.draggingPasteboard.propertyList(forType: .fileURL) as? [String] {
            for path in paths {
                var isDirectory: ObjCBool = false
                if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
                    || isDirectory.boolValue {
                    return []
                }
            }
        }
        return .generic
    }
    
    public func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        guard let handle = self.onURLDropped else { return false }
        
        if let str = sender.draggingPasteboard.string(forType: .string),
            let url = URL(string: str) {
            handle(url)
            return true
        }
        
        if let urls = sender.draggingPasteboard.propertyList(forType: .URL) as? [String],
            let urlStr = urls.first, let url = URL(string: urlStr) {
            handle(url)
            return true
        }
        
//        if let _ = sender.draggingPasteboard.data(forType: .tiff) {
//            return true
//        } else if let paths = sender.draggingPasteboard.propertyList(forType: .fileURL) as? [String] {
////            for path in paths {
////            }
//            return true
//        }
        return false
    }

}
