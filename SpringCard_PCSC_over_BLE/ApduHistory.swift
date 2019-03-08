/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

// No persistence yet
class ApduHistory {
    private var apdus = [Apdu]()
    private var _index = 0
    
    var index: Int {
        return _index
    }
    
    var count: Int {
        return apdus.count
    }
    
    func append(apdu: Apdu) {
        if !apdus.contains(where: {$0 == apdu}) {
            apdus.append(apdu)
            _index = (apdus.count - 1)
        }
    }
    
    func previous() -> Apdu? {
        if apdus.count == 0 {
            return nil
        }
        _index -= 1
        if _index < 0 {
            _index = 0
            return nil
        }
        return apdus[_index]
    }
    
    func next() -> Apdu? {
        if apdus.count == 0 {
            return nil
        }
		_index += 1
        if _index == apdus.count {
            _index = apdus.count - 1
            return nil
        }
        return apdus[_index]
    }
    
    func last() -> Apdu? {
        if apdus.count == 0 {
            return nil
        }
        _index = apdus.count - 1
        return apdus.last
    }
    
    func removeAll() {
        apdus.removeAll()
    }
    
    func hasPreviousAndNext(hasPrevious: inout Bool, hasNext: inout Bool) {
        hasPrevious = false
        hasNext = false
        if apdus.count <= 1 {
            return
        }
        if _index != 0 {
            hasPrevious = true
        }
        if _index != (apdus.count - 1) {
            hasNext = true
        }
    }
}
