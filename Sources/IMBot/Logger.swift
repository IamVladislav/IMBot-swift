//
//  log.swift
//  Testing bot
//
//  Created by v.metel on 11.03.2020.
//  Copyright © 2020 v.metel. All rights reserved.
//

import Foundation

class Log {
    let dir: URL!
    lazy var logFile = dir.appendingPathComponent(Date().description)
    lazy var file: FileHandle? = nil
    var requestData = Dictionary<Int64, String>()
    
    var lastCheckTime: Int64  = Int64(Date().timeIntervalSinceNow)
    let clearTimeInterval: Int64 = 86400
    let maxLogSize: Double = 10000000
    let maxLogCount: Int = 10
    
    init(botName: String) {
        dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(botName).appendingPathComponent("Logs")
        if !FileManager.default.fileExists(atPath: dir.path) {
             do {
                try FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
               } catch {
                   print(error.localizedDescription);
               }
        }
        FileManager.default.createFile(atPath: logFile.path, contents: nil, attributes: nil)
        file = FileHandle(forWritingAtPath: logFile.path)!
    }
    
    deinit {
        file!.closeFile()
    }
    
    func networkLog(_ text: String, requestID: Int64) {
        checkMaxSize()
        
        var logString: String = "[" + NSDate().description + "]\n"
        if let relatedRequest = requestData[requestID] {
            logString.append(relatedRequest + "\n")
            requestData.removeValue(forKey: requestID)
        }
        logString.append(text + "\n\n")
        file!.seekToEndOfFile()
        file!.write(logString.data(using: String.Encoding.utf8)!)
        
        if Int64(Date().timeIntervalSince1970) - lastCheckTime > clearTimeInterval {
            clearLogs()
        }
    }
    
    func clearLogs() {
        if var contents = try? FileManager.default.contentsOfDirectory(atPath: dir.relativePath) {
            if contents.count > maxLogCount {
                contents.sort()
                for i in 0...maxLogCount {
                    do {
                        try FileManager.default.removeItem(atPath: dir.relativePath + "/" + contents[i])
                    } catch {
                        print("Could not clear logs: \(error)")
                    }
                }
            }
        }
        lastCheckTime = Int64(Date().timeIntervalSince1970)
    }
    
    func checkMaxSize() {
        if let size = (try? FileManager.default.attributesOfItem(atPath: logFile.relativePath)[FileAttributeKey.size] as? NSNumber)?.doubleValue {
            if size > maxLogSize {
                logFile = dir.appendingPathComponent(Date().description)
                FileManager.default.createFile(atPath: logFile.path, contents: nil, attributes: nil)
                file = FileHandle(forWritingAtPath: logFile.path)!
            }
        }
    }
}
