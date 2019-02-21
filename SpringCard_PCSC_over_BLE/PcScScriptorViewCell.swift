/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation
import UIKit

class PcScScriptorViewCell:  UITableViewCell {
	
	@IBOutlet weak var signalPicture: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var rssiLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	func didSelect(indexPath: NSIndexPath) {
		
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
}
