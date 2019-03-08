/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

enum CommunicationMode: Int {
	case transmit = 0,
	control = 1,
    none = 2
}

enum IccPower {
    case none
    case on
    case off
    case reconnect
}
