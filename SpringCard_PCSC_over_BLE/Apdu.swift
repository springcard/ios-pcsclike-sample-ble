/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

struct Apdu: Equatable, Decodable {
    var id: Int = 0
    var title: String = ""
    var apdu: String = ""
    var mode: Int = 0
    var created: String = ""
    var modified: String = ""

    init(apdu: String, type: Int) {
        self.apdu = apdu
        self.mode = type
    }

    init(apdu: String, type: CommunicationMode) {
        self.apdu = apdu
        self.mode = type.rawValue
    }
    
    static func == (lhs: Apdu, rhs: Apdu) -> Bool {
        return (lhs.apdu == rhs.apdu) && (lhs.mode == rhs.mode)
    }
}
