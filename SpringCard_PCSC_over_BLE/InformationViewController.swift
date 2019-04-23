/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit
import SpringCard_PcSc_Like

class InformationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var readersData = [(String, String)]()
    public var readers: SCardReaderList!
    @IBOutlet weak var informationTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        informationTableView.dataSource = self
        informationTableView.delegate = self
        loadReadersInformation()
    }
    
    func loadReadersInformation() {
        readersData.removeAll()
        guard let readers = self.readers else {
            return
        }
        readersData.append(("Vendor Name", readers.vendorName))
        readersData.append(("Product Name", readers.productName))
        readersData.append(("Serial Number", readers.serialNumber))
        readersData.append(("Firmware Version", readers.firmwareVersion))
        readersData.append(("Hardware Version", readers.hardwareVersion))
        readersData.append(("Software Version", readers.softwareVersion))
        readersData.append(("Pnp Id", readers.pnpId))
        readersData.append(("Tx Power Level", String(readers.powerLevel)))
        readersData.append(("Battery Level", String(readers.batteryLevel)))
        readersData.append(("Power State", String(readers.powerState)))
        readersData.append(("Slot Count", String(self.readers.slotCount)))

        if self.readers.slotCount > 0 {
            for (index, slot) in readers.slots.enumerated() {
                readersData.append(("Slot \(index)", slot))
            }
        }
		informationTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readersData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "informationCell", for: indexPath) as? InformationTableViewCell {
            let data = readersData[indexPath.row]
            cell.dataLabel.text = data.0
            cell.dataValue.text = data.1
            return cell
        }
        return UITableViewCell()
    }
}
