/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

// temporary solution
class Model {
    private var _apdu = ""
    private var _type: CommunicationMode = .transmit
    
    public var apdu: String {
        return self._apdu
    }
    
    public var type: CommunicationMode {
        return self._type
    }
    
    init(apdu: String, type: CommunicationMode) {
        self._apdu = apdu
        self._type = type
    }
}
