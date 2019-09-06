/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation
import UIKit

class Utilities {
    
    static var log: Log?
    
	static func rssiToPercentage(_ rssiLevel: Int) -> Int {
		let rssi = Double(abs(rssiLevel))
		if(rssi > 95 ) {
			return 0
		}
		
		if(rssi <= 30) {
			return 100
		}
		return Int(round((100 - (rssi - 30))))
	}
	
	static func rssiPercentageToPicture(_ rssiPercentage: Int) -> String {
		var img = ""
		if(rssiPercentage >= 0 && rssiPercentage <= 20) {
			img = "20"
		} else if(rssiPercentage > 20 && rssiPercentage <= 40) {
			img = "40"
		} else if(rssiPercentage > 40 && rssiPercentage <= 60) {
			img = "60"
		} else if(rssiPercentage > 60 && rssiPercentage <= 80) {
			img = "80"
		} else {
			img = "100"
		}
		return img
	}
    
    static func showOkMessageBox(on: UIViewController, message: String?, title: String?, afterShowing: (() -> ())? = nil) {
        Utilities.showOkMessageBox(on: on, message: message, title: title, buttonTitle: "Ok", afterShowing: afterShowing)
    }
    
    static func showOkMessageBox(on: UIViewController, message: String?, title: String?, buttonTitle: String = "Ok", afterShowing: (() -> ())? = nil) {
        if Utilities.log != nil {
            log!.add("Utilitites: " + (title ?? "") + ": " + (message ?? ""))
        }
		let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: buttonTitle, style: .default, handler: { (action) in
			alertVC.dismiss(animated: true, completion: nil)
            if let action = afterShowing {
                action()
            }
		})
		alertVC.addAction(okAction)
		on.present(alertVC, animated: true);
	}
	
	static func getSegmentedControlLabel(_ segment: UISegmentedControl) -> String? {
		return segment.titleForSegment(at: segment.selectedSegmentIndex)
	}
    
    static func hexStringToBytes(_ line: String) -> [UInt8]? {
        var hexString = line.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "0x", with: "")
        hexString = hexString.replacingOccurrences(of: "\n", with: "")
        var hexString2 = ""
        for j in 0 ..< hexString.count {
            let index = hexString.index(hexString.startIndex, offsetBy: j)
            let car = hexString[index]
            if car != " " && car != ":" && car != ";" {
                hexString2 += String(car)
            }
        }
        
        hexString = hexString2
        
        if hexString.isEmpty || (hexString.count % 2 != 0) {
            return nil
        }
        var result = [UInt8](repeating: 0x00, count: hexString.count / 2)
        var cpt = 0
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let startIndex = hexString.index(hexString.startIndex, offsetBy: i)
            let endIndex = hexString.index(hexString.startIndex, offsetBy: i+2)
            let range = startIndex ..< endIndex
            let subsString = hexString[range]
            let byte = UInt8(String(subsString), radix: 16)
            if byte != nil {
                result[cpt] = byte!
            } else {
                return nil
            }
            cpt += 1
        }
        return result
    }
    
    static func showPleaseWait(on: UIViewController) {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        on.present(alert, animated: true, completion: nil)
    }
    
    static func hidePleaseWait(on: UIViewController, afterHide: (() -> ())? = nil) {
        on.dismiss(animated: false, completion: {
            if let action = afterHide {
                action()
            }
        })
    }
    
    static func isASCIIChar(b: UInt8) -> Bool {
        return ((b < 0x20) || (b >= 0x7F)) ? false : true;
    }
    
    static func getASCIIChar(_ b: UInt8) -> String {
        return String(UnicodeScalar(b))
    }

    static func HexStringToAscii(_ text: String) -> String {
        let content = text.trimmingCharacters(in: .whitespaces)
        if content.isEmpty {
            return ""
        }
        let lines = content.components(separatedBy: "\n")
        if lines.isEmpty {
            return ""
        }
        var out = ""
        for (index, line) in lines.enumerated() {
            let lineAsBytes = Utilities.hexStringToBytes(line)
            guard let lineBytes = lineAsBytes else {
                continue
            }
            var s = ""
            for byte in lineBytes {
                if Utilities.isASCIIChar(b: byte) {
                    s += Utilities.getASCIIChar(byte)
                } else {
                    s += " "
                }
            }
            let EOL = (index == lines.count - 1) ? "" : "\n"
            out += s + EOL
        }
        return out
    }
}
