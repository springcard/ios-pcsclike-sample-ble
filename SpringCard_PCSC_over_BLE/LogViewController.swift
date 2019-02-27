/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit

class LogViewController: UIViewController {
    private var log: Log!
    
    @IBOutlet weak var cleanButton: UIBarButtonItem!
    @IBOutlet weak var copyButton: UIToolbar!
    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.log = Log.getInstance()
        displayLogContent()
    }
    
    @IBAction func copyButtonClick(_ sender: UIBarButtonItem) {
        UIPasteboard.general.string = logTextView.text
    }
    
    @IBAction func cleanButtonClick(_ sender: UIBarButtonItem) {
        self.log.clear()
        displayLogContent()
    }
    
    func displayLogContent() {
        logTextView.text = self.log.getAll().joined(separator: "\n")
    }
}
