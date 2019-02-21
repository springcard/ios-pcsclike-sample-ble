/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation
class ApduParser {
    private var rawContent = ""
    private var linesCount = 0
    private var _isParsing = false
    private var currentPosition = -1
    var parsedLines: [String] = []
    
    func setContent(_ content: String) -> Bool {
        rawContent = content
        _isParsing = false
        currentPosition = -1
        rawContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawContent.isEmpty {
            return false
        }
        let lines = rawContent.components(separatedBy: "\n")
        if lines.isEmpty {
            return false
        }
        parsedLines = []
        for line in lines {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parsedLines.append(line)
                linesCount += 1
            }
        }
        return true
    }
    
    init() {}
    
    init(_ content: String) {
        _ = setContent(content)
    }
    
    func getLinescount() -> Int {
        return self.linesCount
    }
    
    func getFirstLine() -> [UInt8]? {
        _isParsing = true
        currentPosition = 0
        return parsedLines.isEmpty ? nil : Utilities.hexStringToBytes(parsedLines[0])
    }
    
    func getNextLine() ->  [UInt8]? {
        currentPosition += 1
        if currentPosition >= linesCount {
            _isParsing = false
            currentPosition = -1
            linesCount = -1
            return nil
        }
        _isParsing = true
        return parsedLines.isEmpty ? nil : Utilities.hexStringToBytes(parsedLines[currentPosition])
    }
    
    func hasContent() -> Bool {
        return linesCount > 0 ? true : false
    }
    
    func isParsing() -> Bool {
        return _isParsing
    }
    
    func stopParsing() {
        _isParsing = false
        currentPosition = linesCount + 1
    }
}
