//
//  MenuViewController.swift
//  BleTest
//
//  Created by proactive on 08/11/2018.
//  Copyright © 2018 proactive. All rights reserved.
// UIViewController

import UIKit

class MenuViewController: UITableViewController {
	
	var menuOptions: [String] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		menuOptions = ["About", "Options", "Log"]
    }
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		tableView.reloadData()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return menuOptions.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
		cell.textLabel?.text = menuOptions[indexPath.row]
		return cell
	}

}
