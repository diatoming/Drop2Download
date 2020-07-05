//
//  AppDelegate.swift
//  Drop2Download
//
//  Created by Diatoming on 6/27/20.
//  Copyright © 2020 diatoming. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItemController = StatusItemController(image: #imageLiteral(resourceName: "arrow.down.right.circle"))

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Register event handler
        let em = NSAppleEventManager.shared()
        em.setEventHandler(self, andSelector: #selector(AppDelegate.handleUrl(_:with:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        setDefault()
        
        self.refreshMenubarMenu()
        
        UNUserNotificationCenter.current().requestPermission { _ in }
        
        statusItemController.onURLDropped = {
            [weak self] url in
            print(url)
            self?.download(from: url, backToSafari: true)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // https://stackoverflow.com/questions/49510/how-do-you-set-your-cocoa-application-as-the-default-web-browser
    @objc func handleUrl(_ event: NSAppleEventDescriptor, with replyEvent: NSAppleEventDescriptor) {
        if let urlStr = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue {
            Swift.print(urlStr)
            if let url = URL(string: urlStr) {
                
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    let items = components.queryItems {
                    let urls = items.compactMap { item -> String? in
                        switch item.name {
                        case "url":
                            return item.value
                        default: return nil
                        }
                    }
                    for str in urls {
                        if let url = URL(string: str) {
                            self.download(from: url)
                        }
                    }
                }
            }
                 
//            self.addURIToTransmission(magnetURL: urlStr, ssnID: self.transmissionSessionID)

        } else {
            print("Error", "Failed to open with unrecognized URL.")
        }
    }
    
    func setDefault() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            LSSetDefaultHandlerForURLScheme("d2d" as CFString, bundleIdentifier as CFString)
        } else {
            assertionFailure("BundleIdenrifier not found!")
        }
    }
    
    private func download(from url: URL, backToSafari: Bool = false) {
        
        if url.absoluteString.contains("youtube.com") {
            self.downloadYoutube(url: url)
        } else {
            // allow youtube-dl download other links if possible
            self.downloadYoutube(url: url)
        }
        
        if backToSafari {
            // switch back to safari
            let safari = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == "com.apple.Safari"
            }.first
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: {
                safari?.activate(options: .activateIgnoringOtherApps)
            })
        }
    }
    
    private func downloadYoutube(url: URL) {
        guard let youtubedlBin = "which youtube-dl".runAsShellCommand()?.trimmingCharacters(in: .whitespacesAndNewlines), !youtubedlBin.isEmpty else { return }
        print(youtubedlBin)
        
        let task = ShellProcess()
        task.url = url.absoluteString
        task.outputDataAvailableHandler = { data in
            
            let str = data.decodedString().lowercased()
            let token = "[download] Destination:".lowercased()
            print(str)
            if str.contains(token) {
                if let r = str.range(of: token) {
                    if let path = str[r.upperBound...].components(separatedBy: .newlines).first {
                        print(path)
                        let url = URL(fileURLWithPath: path.trimmingCharacters(in: .whitespacesAndNewlines))
                        task.title = url.lastPathComponent
                    }
                }
            }
            
            // TODO: parse downloading progress
        }
        task.completionHandler = {
            // delay a bit in case process terminated with no buffer
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                if let task = ShellProcessManager.shared.find(with: task.uuid) {
                    print(task.title as Any)
                    let notiTitle = "✅ Download Completed"
                    //                            let notiSubtitle = "Downloaded to:"
                    let body = task.title ?? task.url ?? task.uuid.uuidString
                    UNUserNotificationCenter.current().postNotification(title: notiTitle, subtitle: "", body: body)
                }
                
                ShellProcessManager.shared.remove(task)
            }
        }
        ShellProcessManager.shared.add(task)
        // TODO: support custom config
        
        // use default config if exist
        let downloadUrl = "'\(url.absoluteString)'"
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if FileManager.default.fileExists(atPath: "\(home)/.config/youtube-dl/config") {
            task.run(command: youtubedlBin, arguments: [downloadUrl])
        } else {
            task.run(command: youtubedlBin, arguments: ["-f", "22/bestvideo[height=720][ext=mp4]+bestaudio[ext=m4a]/best", "-o '~/Downloads/%(title)s.%(ext)s'", "--no-part -R infinite", downloadUrl])
        }
    }
}

extension AppDelegate {
    
    func refreshMenubarMenu() {
        statusItemController.statusItem.menu = generateMenubarMenu()
    }
    
    func generateMenubarMenu() -> NSMenu {
        
        let menu = NSMenu()
        
        menu.addItem(.separator())
        
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "")
        menu.addItem(quit)
        
        return menu
    }
}
