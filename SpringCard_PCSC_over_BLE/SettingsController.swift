/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit

class SettingsController: UIViewController, UITextFieldDelegate {
    
    private let defaults = UserDefaults.standard
    private var debugMode = false
    private var stopOnError = false
    private var useSecureCommunication = false
    private var secureKey: String = ""
    private var keyIndex: Int = 0
    private var settings = Settings()
    private var debugSecureCommunication = true
    
    @IBOutlet weak var debugModeSwitch: UISwitch!
    @IBOutlet weak var stopOnErrorSwitch: UISwitch!
    @IBOutlet weak var useSecureCommunicationSwitch: UISwitch!
    @IBOutlet weak var secureKeyLabel: UILabel!
    @IBOutlet weak var secureKeyText: UITextField!
    @IBOutlet weak var keyIndexSegmentControl: UISegmentedControl!
    @IBOutlet weak var keyIndexLabel: UILabel!

    @IBOutlet weak var debugSecureCommunicationLabel: UILabel!
    @IBOutlet weak var debugSecureCommunicationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        secureKeyText.delegate = self
        loadDefaultValues()
        setUIState()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        secureKey = text
        settings.set(key: "secureKey", secureKey)
        let count = text.count + string.count - range.length
        return count <= 32
    }

    func loadDefaultValues() {
        debugMode = settings.get(key: "activateDebugMode")
        stopOnError = settings.get(key: "stopOnError")
        useSecureCommunication = settings.get(key: "useSecureCommunication")
        secureKey = settings.get(key: "secureKey")
        keyIndex = settings.get(key: "keyIndex")
        debugSecureCommunication = settings.get(key: "debugSecureCommunication")
    }
    
    func setUIState() {
        let animated = true
        debugModeSwitch.setOn(debugMode, animated: animated)
        stopOnErrorSwitch.setOn(stopOnError, animated: animated)
        useSecureCommunicationSwitch.setOn(useSecureCommunication, animated: animated)
        secureKeyText.text = secureKey
        
        debugSecureCommunicationLabel.isEnabled = useSecureCommunication
        debugSecureCommunicationSwitch.isEnabled = useSecureCommunication
        secureKeyLabel.isEnabled = useSecureCommunication
        secureKeyText.isEnabled = useSecureCommunication
        keyIndexSegmentControl.isEnabled = useSecureCommunication
        keyIndexLabel.isEnabled = useSecureCommunication
        debugSecureCommunicationSwitch.setOn(debugSecureCommunication, animated: animated)
        if useSecureCommunication {
            keyIndexSegmentControl.selectedSegmentIndex = keyIndex
        }
    }
    
    // **********
    // * Events *
    // **********
    @IBAction func debugModeSwitchClick(_ sender: UISwitch) {
        debugMode = sender.isOn
        settings.set(key: "activateDebugMode", debugMode)
        setUIState()
    }
    
    @IBAction func debugSecureCommunicationSwitchClick(_ sender: UISwitch) {
        debugSecureCommunication = sender.isOn
        settings.set(key: "debugSecureCommunication", debugSecureCommunication)
        setUIState()
    }
    
    @IBAction func stopOnErrorSwitchClick(_ sender: UISwitch) {
        stopOnError = sender.isOn
        settings.set(key: "stopOnError", stopOnError)
        setUIState()
    }
    
    @IBAction func useSecureCommunicationClick(_ sender: UISwitch) {
        useSecureCommunication = sender.isOn
        settings.set(key: "useSecureCommunication", useSecureCommunication)
        setUIState()
    }
    
    @IBAction func keyIndexSegmentClick(_ sender: UISegmentedControl) {
        keyIndex = sender.selectedSegmentIndex
        settings.set(key: "keyIndex", keyIndex)
        setUIState()
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            settings.set(key: "secureKey", secureKeyText.text ?? "")
        }
    }
}
