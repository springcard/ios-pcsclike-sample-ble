/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

class Log {
    private var debugLines = [String]()
    private var withNsLog = true
    private static var instance: Log?
    
    static func getInstance(withNsLog: Bool = true) -> Log {
        if self.instance == nil {
            self.instance = Log(withNsLog: withNsLog)
        }
        return self.instance!
    }
    
    private init(withNsLog: Bool = true) {
        self.withNsLog = withNsLog
        clear()
    }
    
    func add(_ line: String) {
        if !UserDefaults.standard.bool(forKey: "activateDebugMode") {
            return
        }
        if self.withNsLog {
            NSLog(line)
        }
        self.debugLines.append(line)
    }
    
    func getAll() -> [String] {
        return self.debugLines
    }
    
    func clear() {
        debugLines = [String]()
    }
}
