/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation
class Settings {
	private let defaults = UserDefaults.standard
    
    func get(key: String) -> Bool {
     	return defaults.bool(forKey: key)
    }
    
    func get(key: String, default: String = "") -> String {
        return defaults.string(forKey: key) ?? ""
    }
    
    func get(key: String) -> Int {
        return defaults.integer(forKey: key)
    }
    
    func set(key: String, _ value: Bool) {
        defaults.set(value, forKey: key)
    }
    
    func set(key: String, _ value: String) {
        defaults.set(value, forKey: key)
    }
    
    func set(key: String, _ value: Int) {
        defaults.set(value, forKey: key)
    }
}
