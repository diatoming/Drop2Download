//
//  ShellProcess.swift
//  Drop2Download
//
//  Created by Diatoming on 6/27/20.
//  Copyright © 2020 diatoming. All rights reserved.
//

import Foundation

/// Process wrapper to run shell command from bash/sh
public class ShellProcess {
    
    let uuid = UUID()
    private(set) var buffer = Data()
    private var outHandle: FileHandle?
    private let outputPipe = Pipe()
    
    public var url: String?
    public var title: String?
    
    public var completionHandler: (() -> Void)?
    public var outputDataAvailableHandler: ((Data) -> Void)?
    
    public func run(command: String, arguments: [String] = []) {
        
        let bin = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var args:[String] = []
        args.append("-c")
        args.append("-l")
        
        let cmd = bin + " " + arguments.joined(separator: " ")
        args.append(cmd)
        
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = args
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        process.standardOutput = outputPipe
        
        self.outHandle = outputPipe.fileHandleForReading
        
//        process.waitUntilExit()
        process.terminationHandler = { task in
            self.completionHandler?()
            print("\(task) - EOF")
        }
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outHandle, queue: nil) {
            [weak self] noti in
            guard let self = self else { return }
            if let data = self.outHandle?.availableData, !data.isEmpty {
                self.outputDataAvailableHandler?(data)
                self.buffer.append(data)
                self.outHandle?.waitForDataInBackgroundAndNotify()
            }
        }
        
        try? process.run()
    }
}

// MARK: - Equatable, Hashable
extension ShellProcess: Equatable, Hashable {
    public static func == (lhs: ShellProcess, rhs: ShellProcess) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

// MARK: - Sync running shell command
extension String {
    public func runAsShellCommand() -> String? {
        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "-l", self]
        process.standardOutput = pipe
        
        let fileHandle = pipe.fileHandleForReading
        try? process.run()
        
        return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
    }
}
