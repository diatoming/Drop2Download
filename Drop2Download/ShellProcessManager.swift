//
//  ShellProcessManager.swift
//  Drop2Download
//
//  Created by Diatoming on 6/28/20.
//  Copyright © 2020 diatoming. All rights reserved.
//

import Foundation

final class ShellProcessManager {
    static let shared = ShellProcessManager()
    
    private(set) var tasks: Set<ShellProcess> = []
    
    private init() {
        
    }
    
    func find(with uuid: UUID) -> ShellProcess? {
        tasks.filter{ $0.uuid == uuid}.first
    }
    
    func add(_ task: ShellProcess) {
        self.tasks.insert(task)
    }
    
    func remove(_ task: ShellProcess) {
        self.tasks.remove(task)
    }
}
