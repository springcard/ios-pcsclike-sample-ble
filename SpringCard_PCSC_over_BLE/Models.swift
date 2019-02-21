/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

class Models {
    private var _models = [Model]()
    private var _currentIndex = -1
    
    public subscript(_ index: Int) -> Model? {
        if index < 0 || index >= self._models.count {
            return nil
        }
        _currentIndex = index
        return self._models[index]
    }
    
    func isEmpty() -> Bool {
        return self._models.isEmpty
    }
    
    func count() -> Int? {
        return self._models.count
    }
    
    init() {
        setInitialContent()
    }
    
    func next() -> Model {
        _currentIndex += 1
        if _currentIndex >= self._models.count {
            _currentIndex = 0
        }
        return _models[_currentIndex]
    }
    
    func setInitialContent() {
        #warning("There must be, at least, one Model, even if we are waiting for the Rest server")
        _models.append(Model(apdu: "ff:ca:fa:00", type: .transmit))  // Card' ATR
        _models.append(Model(apdu: "589F", type: .control))  // Wink
        _models.append(Model(apdu: "582002", type: .control))  // Product's name
        _models.append(Model(apdu: "582001", type: .control))  // Vendor's name
        _models.append(Model(apdu: "FF CA 00 00 00", type: .transmit))  // Get UID
    }
}
