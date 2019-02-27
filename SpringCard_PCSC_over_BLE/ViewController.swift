/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit
import CoreBluetooth
import SpringCard_PcSc_Like

@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate {

	public var centralManager: CBCentralManager!
	var isScanning = false

	// Variables used to store discovered peripherals and their characteristics
	private var discoveredPeripheralsUUID: [String] = []
	private var discoveredPeripheralsDetails: [String: (peripheral: CBPeripheral, rssi: NSNumber, AdervtisingService: [CBUUID])] = [:]
    private var log: Log!
	@IBOutlet weak var tabelView: UITableView!
    
	override func viewDidLoad() {
		super.viewDidLoad()
        self.log = Log.getInstance()
		tabelView.dataSource = self
		tabelView.delegate = self
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
    
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.discoveredPeripheralsUUID.count
	}
	
	// Display a cell
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? PcScScriptorViewCell {
			let tableIndex = indexPath.row
			if !self.discoveredPeripheralsUUID.indices.contains(tableIndex) {
				return cell
			}
		
			let deviceUUID = self.discoveredPeripheralsUUID[tableIndex]
			if let deviceDetails = self.discoveredPeripheralsDetails[deviceUUID] {
				let peripheral = deviceDetails.peripheral
				let rssi = deviceDetails.rssi
				let image = Utilities.rssiPercentageToPicture(Utilities.rssiToPercentage(rssi.intValue))
				cell.nameLabel.text = peripheral.name ?? String()
				cell.rssiLabel.text = "RSSI: \(rssi)"
				cell.signalPicture.image = UIImage(named: image)
			}
			return cell
		}
		return UITableViewCell()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "deviceConnectSegue", sender: self)
	}

	func startScanning() {
		if isScanning {
			return
		}
		isScanning = true
        log.add("Starting scanning")
		// Get the list of devices services to filter
		let servicesToScan:[CBUUID] = SCardReaderList.getAllAdvertisingServices()
		centralManager.scanForPeripherals(withServices: servicesToScan, options: nil)
	}
	
	func stopScanning() {
		if !isScanning {
			return
		}
        log.add("Stopping scanning")
		isScanning = false
		centralManager.stopScan()
	}
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		// requires iOS10 (CBManagerState.poweredOn)
		if central.state == CBManagerState.poweredOn {
            log.add("Bluetooth is ok")
			self.discoveredPeripheralsDetails = [:]
			self.discoveredPeripheralsUUID = []
			startScanning()
		} else {
            log.add("Problem with Bluetooth")
			let alertVC = UIAlertController(title: "Bluetooth isn't working", message: "Make sure your bluetooth is on and ready", preferredStyle: .alert)
			let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
				alertVC.dismiss(animated: true, completion: nil)
			})
			alertVC.addAction(okAction)
			present(alertVC, animated: true, completion: nil)
		}
	}
	
	// When a device is detected
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		let deviceName = peripheral.name ?? String()
		if !deviceName.isEmpty {
			if !self.discoveredPeripheralsUUID.contains(peripheral.identifier.uuidString) {
                
				self.discoveredPeripheralsUUID.append(peripheral.identifier.uuidString)
				let key = peripheral.identifier.uuidString
				let value = (peripheral: peripheral, rssi: RSSI, AdervtisingService: advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID])
				self.discoveredPeripheralsDetails[key] = value
                log.add("Device detected \(key)")
			}
		}
		tabelView.reloadData()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "deviceConnectSegue" {
            guard let tableIndex = tabelView.indexPathForSelectedRow?.row else {
                return
            }
			stopScanning()
			//let tableIndex = tabelView.indexPathForSelectedRow!.row
			if !self.discoveredPeripheralsUUID.indices.contains(tableIndex) {
				return
			}
			
			let deviceUUID = self.discoveredPeripheralsUUID[tableIndex]
			if let deviceDetails = self.discoveredPeripheralsDetails[deviceUUID] {
				let destinationViewControler = segue.destination as! ConnectViewController
				destinationViewControler.device = deviceDetails.peripheral
				destinationViewControler.advertisingServices = deviceDetails.AdervtisingService
				destinationViewControler.centralManager = centralManager
			}
		}
	}
}
