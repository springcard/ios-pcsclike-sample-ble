/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit
import SpringCard_PcSc_Like

class AboutViewController: UIViewController {
	
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var libraryNameLabel: UILabel!
    @IBOutlet weak var libraryVersionLabel: UILabel!
    @IBOutlet weak var libraryDebugLabel: UILabel!
    @IBOutlet weak var springcardLinkLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String) ?? ""
		libraryNameLabel.text = SCardReaderList.libraryName
		libraryVersionLabel.text = SCardReaderList.libraryVersion
        libraryDebugLabel.text = String(SCardReaderList.libraryDebug)
        
        let tapOnLinkLabel = UITapGestureRecognizer(target: self, action: #selector(AboutViewController.tapOnLinkLabel))
        springcardLinkLabel.isUserInteractionEnabled = true
        springcardLinkLabel.addGestureRecognizer(tapOnLinkLabel)

    }
    
    @objc func tapOnLinkLabel(sender:UITapGestureRecognizer) {
        guard let url = URL(string: "https://www.springcard.com") else { return }
        UIApplication.shared.open(url)
    }
}
