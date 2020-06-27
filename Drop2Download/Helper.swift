//
//  Helper.swift
//  Drop2Download
//
//  Created by Diatoming on 6/28/20.
//  Copyright © 2020 diatoming. All rights reserved.
//

import Foundation
import UserNotifications

public extension UNUserNotificationCenter {
    func requestPermission(completion handler: @escaping (Bool) -> Void) {
        // Request permission to display alerts and play sounds.
        self.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Enable or disable features based on authorization.
            handler(granted)
        }
    }
    
}

// MARK: - User Notification
extension UNUserNotificationCenter  {
    func postNotification(with deadline: TimeInterval = 1, title: String, subtitle: String, body: String, sound: UNNotificationSound? = nil, attachments: [UNNotificationAttachment] = [], registerCategories handler: (() -> Void)? = nil) {
        // check center settings
        self.getNotificationSettings { (settings) in
            // Do not schedule notifications if not authorized.
            guard settings.authorizationStatus == .authorized else {return}
            
            if settings.alertSetting == .enabled {
                // Schedule an alert-only notification.
            } else {
                // Schedule a notification with a badge and sound.
            }
        }
        
        #if canImport(Cocoa)
        self.requestPermission { [weak self] granted in
            guard granted else { return }
            
            guard let self = self else { return }
            
            // it is the safest place
            handler?()
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.body = body
            //            content.badge
            
            content.sound = sound
            content.attachments = attachments
            
            let interval = max(deadline, 1)
            // Deliver the notification in 1 seconds.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            // Create the request
            let uuidString = UUID().uuidString
            
            // cache notification with its associated info
            //         self.userInfo[uuidString] = self
            
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            // Schedule the request with the system.
            self.add(request) { error in
                if error != nil {
                    // Handle any errors.
                    //                    assertionFailure(error!.localizedDescription)
                    assertionFailure(error!.localizedDescription)
                }
            }
        }
        #endif
        #warning("ios")
    }
}

extension Data {
    func decodedString() -> String {
        
//        if let str = String(data: self, encoding: .gb_18030_2000) {
//            return str
//        }
        
//        if let str = String(data: self, encoding: .iso2022JP) {
//            return str
//        }
        
        return String(decoding: self, as: UTF8.self)
    }
}

extension String.Encoding {
    static let gb_18030_2000 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}
