/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit

class MenuTableViewController: UITableViewController {

	var menuOptions : [String] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		menuOptions = ["About", "Options", "Log"]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOptions.count
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		tableView.reloadData()
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
		cell.textLabel?.text = menuOptions[indexPath.row]
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let menuIndex = indexPath.row
		if menuIndex < 0 || menuIndex > menuOptions.count {
			return
		}
		
		let segueName: String;
		switch(menuIndex) {
			case 0:
				segueName = "showAboutSegue"
			case 1:
				segueName = "showOptionsSegue"
			case 2:
				segueName = "showLogSegue"
			default:
				segueName = "showAboutSegue"
		}
		self.performSegue(withIdentifier: segueName, sender: self)
	}

}
