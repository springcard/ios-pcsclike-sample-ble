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
    private var _isValid = true
    var parsedLines: [String] = []
    
    var isValid: Bool {
        return _isValid
    }
    
    func setContent(_ content: String) {
        rawContent = content
        linesCount = 0
        _isParsing = false
        currentPosition = -1
        parsedLines = []
        _isValid = true
        rawContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawContent.isEmpty {
            _isValid = false
            return
        }
        let lines = rawContent.components(separatedBy: "\n")
        if lines.isEmpty {
            _isValid = false
            return
        }
        parsedLines = []
        for line in lines {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parsedLines.append(line)
                linesCount += 1
            }
        }
    }
    
    init() {}
    
    init(_ content: String) {
        setContent(content)
    }
    
    func getLinescount() -> Int {
        return linesCount
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
