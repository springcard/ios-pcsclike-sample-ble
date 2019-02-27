/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit

class AboutViewController: UIViewController {
	
	@IBOutlet weak var webView: UIWebView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let url = URL (string: "https://www.springcard.com/en/copyright.html")
		let request = URLRequest(url: url!);
		webView.loadRequest(request);
    }

}
