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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
