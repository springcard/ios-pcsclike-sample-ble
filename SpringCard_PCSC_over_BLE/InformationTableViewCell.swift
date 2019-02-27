/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit

class InformationTableViewCell: UITableViewCell {

    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var dataValue: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
