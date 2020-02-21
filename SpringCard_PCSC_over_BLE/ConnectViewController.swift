/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import UIKit
import CoreBluetooth
import os.log
import SpringCard_PcSc_Like

typealias Byte = UInt8
extension Collection where Element == Byte {
    var data: Data {
        return Data(self)
    }
    var hexa: String {
        return map{ String(format: "%02X", $0) }.joined()
    }
}

class ConnectViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, SCardReaderListDelegate {
    public var device: CBPeripheral?
    public var advertisingServices: [CBUUID] = []
    public var centralManager: CBCentralManager!
    private var readers: SCardReaderList!
    private var reader: SCardReader?
    private var channel: SCardChannel?
    private var channels: [Int: SCardChannel] = [:]
    private var selectedActionIndex = 0
    private var selectedReaderIndex = 0
    private var selectedActionName = ""
    private var settings = Settings()
    private var stopOnError = false
    private var measureTimeExecution = false
    private var log: Log!
    private var apduHistory = ApduHistory()
    private var models = Models.getInstance()
    let parser = ApduParser()
    private let WAKEUP = "Wake up"
    private let SHUTDOWN = "Shutdown"
    private let GET_BATTERY_LEVEL = "Get battery level"
    private let INFO = "Info."
    private var didHidePleaseWait = false
    private var startingPoint = Date()
    
    // MARK: - Interface objects
    @IBOutlet weak var deviceTitle: UINavigationItem!
    @IBOutlet weak var capdu: UITextView!
    @IBOutlet weak var transmitControlInterrupt: UISegmentedControl!
    @IBOutlet weak var connectionStatus: UILabel!
    @IBOutlet weak var rapdu: UITextView!
    @IBOutlet weak var atrLabel: UILabel!
    @IBOutlet weak var statusWordLabel: UILabel!
    @IBOutlet weak var modelsButton: UIButton!
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var iccPowerButton: UIButton!
    @IBOutlet weak var slotButton: UIButton!
    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var stateButton: UIButton!
    // *************************************************************
    
    // MARK: - Internal state
    var isSleeping = false
    var communicationMode: CommunicationMode = .transmit
    
    private var isConnected = false
    private var iccPowerButtonIsEnabled = true
    
    // Used to "translate" (hex string to ASCII) RAPDU ********
    var translateState: Bool = false
    var rapduBackup: String = ""
    // ********************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stopOnError = settings.get(key: "stopOnError")
        self.measureTimeExecution = settings.get(key: "measureTimeExecution")
        self.models.loadModelsAsync()
        rapdu.text = ""
        self.log = Log.getInstance()
        Utilities.log = self.log
        Utilities.showPleaseWait(on: self)
        centralManager.delegate = self
        self.centralManager.connect(self.device!)
        emptyTextFields()
        setDeviceTitle()
        setConnectionStateLabel("Connecting")
        setRapduCapduLookAndFeel()
        addGestures()
        rapdu.text = ""
        manageHistoryButtons()
        capdu.text = ""
    }
    
    private func addGestures() {
        let tapOnResponse = UITapGestureRecognizer(target: self, action: #selector(ConnectViewController.tapOnResponseLabel))
        responseLabel.isUserInteractionEnabled = true
        responseLabel.addGestureRecognizer(tapOnResponse)
        
        let tapOnView = UITapGestureRecognizer(target: self, action: #selector(ConnectViewController.dismissKeyboard))
        view.addGestureRecognizer(tapOnView)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func tapOnResponseLabel(sender:UITapGestureRecognizer) {
        rapdu.text = ""
    }
    
    private func getSecureConnectionParameters() -> SecureConnectionParameters? {
        if !settings.get(key: "useSecureCommunication") {
            return nil
        }
        guard let secureKey = Utilities.hexStringToBytes(settings.get(key: "secureKey")) else {
            return nil
        }
        
        let keyIndexFromSettings: Int = settings.get(key: "keyIndex")
        guard let keyIndex: KeyIndex = KeyIndex(rawValue: UInt8(keyIndexFromSettings)) else {
            return nil
        }
        let debugCommunication: Bool = settings.get(key: "debugSecureCommunication")
        return SecureConnectionParameters(authMode: .Aes128, keyIndex: keyIndex, keyValue: secureKey, commMode: .secure, debugSecureCommunication: debugCommunication)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        let secureParameters = getSecureConnectionParameters()
        SCardReaderList.create(peripheral: self.device!, centralManager: self.centralManager, delegate: self, secureConnectionParameters: secureParameters)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != CBManagerState.poweredOn {
            showErrorAndGoBack(message: "Please activate Bluetooth", title: "Error")
            return
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if isConnected {
            log.add("Ask for disconnecting")
            if self.readers != nil {
                self.readers.close(keepBleActive: false)
            }
        }
    }
    
    
    // ********************************************************
    // MARK: Manage UI fields (content, state and appearance) *
    // ********************************************************
    
    func setRapduCapduLookAndFeel() {
        let color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        capdu.layer.borderWidth = 1
        capdu.layer.borderColor = color
        rapdu.layer.borderWidth = 1
        rapdu.layer.borderColor = color
    }
    
    // Remove text & label fields who have content
    func emptyTextFields() {
        setCapdu(text: "")
        connectionStatus.text = ""
        setRapdu(text: "")
        atrLabel.text = ""
        setStatusWordLabel("")
    }
    
    func setStatusWordLabel(_ content: String) {
        statusWordLabel.text = content
    }
    
    func setStatusWordLabel(_ bytes: [UInt8]) {
        setStatusWordLabel(bytes.hexa)
    }
    
    func setAtrText(_ value: String) {
        self.atrLabel.text = value
    }
    
    func setCapdu(text: String) {
        self.capdu.text = text
    }
    
    func setRapdu(text: String) {
        self.rapdu.text += text + "\n"
    }
    
    func setRapdu(bytes: [UInt8]) {
        setRapdu(text: bytes.hexa)
    }
    
    func setSegmentCommunicationMode(_ communicationMode: CommunicationMode) {
        self.communicationMode = communicationMode
        if self.communicationMode == .control {
            transmitControlInterrupt.selectedSegmentIndex = 1
        } else {
            transmitControlInterrupt.selectedSegmentIndex = 0
        }
    }
    
    // Change the connection state (label) in the bottom left of the screen
    private func setConnectionStateLabel(_ state: String) {
        connectionStatus.text = state
    }
    
    // Manage the state of the "Slots" button according to the number of slots
    func setSlotsButtonState() {
        slotButton.isEnabled = self.readers.slotCount > 0 ? true : false
    }
    
    func setSlotbuttonLabel(_ label: String) {
        slotButton.setTitle(label, for: .normal)
    }
    
    // We pass the current state so that it displays the next possible status
    func setIccPowerButtonLabel(_ state: IccPower) {
        let label: String
        iccPowerButton.isEnabled = true
        switch state {
        case .none:
            label = "no card"
            iccPowerButton.isEnabled = false
        case .off:
            label = "Connect"
        case .on:
            label = "Disconnect"
        case .reconnect:
            label = "reconnect"
        case .error:
            label = "Error"
        }
        iccPowerButton.setTitle(label, for: .normal)
    }
    
    func setDeviceTitle(_ isSleeping: Bool = false) {
        let sleep = isSleeping ? " (Zz)" : ""
        let deviceName = device?.name ?? "no device name"
        deviceTitle.title = deviceName + sleep
    }
    
    // ************************************************
    // MARK: - UI Actions (buttons and segments clicks)
    // ************************************************
    
    func disableUI() {
        capdu.isUserInteractionEnabled = false
        transmitControlInterrupt.isEnabled = false
        rapdu.isUserInteractionEnabled = false
        modelsButton.isEnabled = false
        translateButton.isEnabled = false
        nextButton.isEnabled = false
        previousButton.isEnabled = false
        runButton.isEnabled = false
        copyButton.isEnabled = false
        iccPowerButtonIsEnabled = iccPowerButton.isEnabled
        iccPowerButton.isEnabled = false
        slotButton.isEnabled = false
        responseLabel.isUserInteractionEnabled = false
    }
    
    func enableUI() {
        if (self.measureTimeExecution) {
            showExecutionTime()
        }
        capdu.isUserInteractionEnabled = true
        transmitControlInterrupt.isEnabled = true
        rapdu.isUserInteractionEnabled = true
        modelsButton.isEnabled = true
        translateButton.isEnabled = true
        manageHistoryButtons()
        runButton.isEnabled = true
        copyButton.isEnabled = true
        iccPowerButton.isEnabled = iccPowerButtonIsEnabled 
        setSlotsButtonState()
        responseLabel.isUserInteractionEnabled = true
        runButton.shake()
    }
    
    @IBAction func onModelsClick(_ sender: UIButton) {
    }
    
    @IBAction func onTranslateClick(_ sender: Any) {
        translateState = !translateState
        if translateState { // To ASCII
            rapduBackup = rapdu.text
            rapdu.text = Utilities.HexStringToAscii(rapduBackup)
        } else { // Back to hex
            rapdu.text = rapduBackup
        }
    }
    
    func manageHistoryButtons() {
        var previousButtonEnabled = true
        var nextButtonEnabled = true
        apduHistory.hasPreviousAndNext(hasPrevious: &previousButtonEnabled, hasNext: &nextButtonEnabled)
        previousButton.isEnabled = previousButtonEnabled
        nextButton.isEnabled = nextButtonEnabled
    }
    
    private func setPreviousAndNextState(_ apdu: Apdu) {
        setCapdu(text: apdu.apdu)
        if CommunicationMode(rawValue: apdu.mode) == .control {
            communicationMode = .control
        } else if CommunicationMode(rawValue: apdu.mode) == .transmit {
            communicationMode = .transmit
        }
        manageHistoryButtons()
    }
    
    func setModel(_ apdu: Apdu?) {
        guard let model = apdu else {
            return
        }
        setCapdu(text: model.apdu)
        setSegmentCommunicationMode(CommunicationMode(rawValue: model.mode)!)
    }
    
    @IBAction func onPreviousApduClick(_ sender: Any) {
        guard let apdu = apduHistory.previous() else {
            return
        }
        setPreviousAndNextState(apdu)
    }
    
    @IBAction func onNextApduClick(_ sender: Any) {
        guard let apdu = apduHistory.next() else {
            return
        }
        setPreviousAndNextState(apdu)
    }
    
    @IBAction func onCopyClick(_ sender: Any) {
        let content = rapdu.text ?? ""
        let items = [content]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
        if let popOver = ac.popoverPresentationController {
            popOver.sourceView = self.view
        }
    }
    
    @IBAction func onRunClick(_ sender: Any) {
        setStatusWordLabel("")
        translateState = false
        if self.communicationMode == .transmit {
            if self.channel == nil {
                Utilities.showOkMessageBox(on: self, message: "Channel is nil, card may be mute", title: "Error")
                return
            }
        } else {
            if self.reader == nil {
                Utilities.showOkMessageBox(on: self, message: "Reader is nil", title: "Error")
                return
            }
        }
        parser.setContent(capdu.text)
        if !parser.hasContent() || !parser.isValid {
            Utilities.showOkMessageBox(on: self, message: "There's no content to send or the content is invalid", title: "Warning")
            return
        }
        guard let apdu = parser.getFirstLine() else {
            Utilities.showOkMessageBox(on: self, message: "ADPU is invalid", title: "Error")
            return
        }
        self.startingPoint = Date()
        disableUI()
        runApdu(apdu: apdu)
    }
    
    private func runApdu(apdu: [UInt8]) {
        apduHistory.append(apdu: Apdu(apdu: apdu.hexa, type: self.communicationMode.rawValue))
        manageHistoryButtons()
        if self.communicationMode == .transmit {
            guard let channel = self.channels[self.selectedReaderIndex] else {
                showErrorAndGoBack(message: "No channel for this reader, card may be mute", title: "Error")
                return
            }
            self.channel = channel
            channel.transmit(command: apdu)
        } else {
            guard let reader = self.readers[self.selectedReaderIndex] else {
                showErrorAndGoBack(message: "Can't find the selected reader", title: "Error")
                return
            }
            self.reader = reader
            reader.control(command: apdu)
        }
    }
    
    func showExecutionTime() {
        let elaspedTime = NSString(format: "%.4f", startingPoint.timeIntervalSinceNow * -1)
        let alertController = UIAlertController(title: (elaspedTime as String) + " sec.", message: nil, preferredStyle:.alert)
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = self.runButton
            presenter.sourceRect = self.runButton.bounds
        }
        self.present(alertController, animated: true, completion: {Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
            self.dismiss(animated: true, completion: nil)
        })})
    }
    
    func showActionSheet(title: String, sourceView: UIButton, elements: [String], afterConfirm: (() -> ())? = nil) {
        let actionsMenu = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        actionsMenu.modalPresentationStyle = .popover
        
        for (index, element) in elements.enumerated() {
            let elementAction = UIAlertAction(title: element, style: .default, handler: { action in
                if let action = afterConfirm {
                    self.selectedActionName = element
                    self.selectedActionIndex = index
                    action()
                }
            })
            actionsMenu.addAction(elementAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionsMenu.addAction(cancelAction)
        
        if let presenter = actionsMenu.popoverPresentationController {
            presenter.sourceView = sourceView
            presenter.sourceRect = sourceView.bounds
        }
        self.present(actionsMenu, animated: true, completion: nil)
    }
    
    @IBAction func onSlotClick(_ sender: Any) {
        var slots = [String]()
        for slot in self.readers.slots {
            slots.append(slot)
        }
        showActionSheet(title: "Select slot:", sourceView: slotButton, elements: slots, afterConfirm: {
            guard let reader = self.readers.getReader(slot: self.selectedActionIndex) else {
                self.log.add("Error, getting reader returned nil")
                return
            }
            self.selectedReaderIndex = self.selectedActionIndex
            self.reader = reader
            if self.channels[reader.index] != nil {
                self.channel = self.channels[reader.index]
            }
            self.setSlotbuttonLabel(self.selectedActionName)
            
            if reader.cardPresent {
                reader.cardConnect()
            } else {
                self.setIccPowerButtonLabel(IccPower.none)
            }
        })
    }
    
    @IBAction func stateButtonClick(_ sender: UIButton) {
        var actions = [String]()
        actions.append(self.isSleeping ?  self.WAKEUP : self.SHUTDOWN)
        actions.append(self.INFO)
        actions.append(self.GET_BATTERY_LEVEL)
        showActionSheet(title: "Select action:", sourceView: stateButton, elements: actions, afterConfirm: {
            guard let readers = self.readers else {
                return
            }
            switch (self.selectedActionName) {
            case self.WAKEUP:
                readers.wakeUp()
            case self.SHUTDOWN:
                readers.shutdown()
            case self.INFO:
                self.performSegue(withIdentifier: "informationSegue", sender: self)
            case self.GET_BATTERY_LEVEL:
                self.readers.getPowerInfo()
            default:
                return
            }
            self.selectedActionName = ""
            self.selectedActionIndex = -1
        })
    }
    
    @IBAction func onPowerOnOffClick(_ sender: Any) {
        guard let reader = self.reader else {
            return
        }
        if self.channel != nil {
            channel?.cardDisconnect()
        } else {
            reader.cardConnect()
        }
    }
    
    @IBAction func onCommunicationModeChange(_ sender: Any) {
        let segmentIndex = self.transmitControlInterrupt.selectedSegmentIndex
        if segmentIndex == 0 {
            self.communicationMode = .transmit
        } else {
            self.communicationMode = .control
        }
    }
    
    // ******************
    // MARK: - Misc funcs
    // ******************
    func _showErrorAndGoBack(message: String, title: String = "Error") {
        Utilities.showOkMessageBox(on: self, message: message, title: title, afterShowing: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    func showErrorAndGoBack(message: String, title: String) {
        _showErrorAndGoBack(message: message, title: title)
    }
    
    func showErrorAndGoBack(_ error: Error?) {
        guard let error = error else {
            return
        }
        let errorCode = String(error._code)
        let errorMessage = error.localizedDescription
        _showErrorAndGoBack(message: ("Code: \(errorCode), \(errorMessage)"), title: "Error")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "informationSegue" {
            if let readersDiscovered = self.readers {
                let destinationViewControler = segue.destination as! InformationViewController
                destinationViewControler.readers = readersDiscovered
            }
        } else if segue.identifier == "modelsSegue" {
            let destinationViewControler = segue.destination as! ModelsViewController
            destinationViewControler.connectViewController = self
        }
    }
    
    // ***********************
    // MARK: - Lib's Callbacks
    // ***********************
    func onReaderStatus(reader: SCardReader?, present: Bool?, powered: Bool?, error: Error?) {
        log.add("onReaderStatus()")
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        guard let reader = reader else {
            readers.close()
            showErrorAndGoBack(message: "Reader is nil and error is not nil!!", title: "Error")
            return
        }
        
        if self.reader != reader {
            return
        }
        self.reader = reader
        if reader.cardPresent {
            log.add("ConnectViewController: card present")
            if !reader.cardPowered {
                reader.cardConnect()
            } else {
                setIccPowerButtonLabel(IccPower.on)
            }
        } else {
            setIccPowerButtonLabel(IccPower.none)
            log.add("ConnectViewController: card absent")
        }
    }
    
    func onParsingError(message: String?) {
        if message != nil {
            setRapdu(text: message!)
        }
        if !self.parser.isParsing() {
            return
        }
        if self.stopOnError {
            enableUI()
            self.parser.stopParsing()
        } else {
            guard let apdu = self.parser.getNextLine() else {
                return
            }
            self.runApdu(apdu: apdu)
        }
    }
    
    func onParsingSuccess() {
        if !self.parser.isParsing() {
            enableUI()
            return
        }
        guard let apdu = self.parser.getNextLine() else {
            enableUI()
            return
        }
        self.runApdu(apdu: apdu)
    }
    
    // When we are getting an answer from the card
    func onTransmitDidResponse(channel: SCardChannel?, response: [UInt8]?, error: Error?) {
        log.add("onTransmitDidResponse()")
        if error != nil {
            log.add("There was an error during transmit: " + String(error?._code ?? -1) + ": " + (error?.localizedDescription ?? "no error message"))
            onParsingError(message: error!.localizedDescription)
            return
        }
        guard let bytes = response else {
            log.add("Response is nil")
            onParsingError(message: "Response is nil")
            return
        }
        if bytes.count <= 2 {
            //setRapdu(text: "")
            setStatusWordLabel(bytes)
        } else {
            let index = (bytes.count - 2)
            let swBytes = (Array(bytes[index...]))
            setRapdu(text: bytes.hexa)
            setStatusWordLabel(swBytes)
        }
        onParsingSuccess()
    }
    
    // When we are getting an answer from the reader
    func onControlDidResponse(readers: SCardReaderList?, response: [UInt8]?, error: Error?) {
        log.add("onControlDidResponse()")
        if error != nil {
            onParsingError(message: error!.localizedDescription)
            return
        }
        
        guard let bytes = response else {
            onParsingError(message: "Response is nil")
            return
        }
        
        setStatusWordLabel("")
        setRapdu(text: bytes.hexa)
        onParsingSuccess()
    }
    
    func onCardDidDisconnect(channel: SCardChannel?, error: Error?) {
        log.add("onCardDidDisconnect()")
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        if channel != nil {
            log.add("Channel index: " + String(channel?.parent.index ?? -1))
            log.add("Channel name: " + (channel?.parent.name ?? "unknown"))
            let channelIndex = channel?.parent.index ?? -1
            if channelIndex >= 0 {
                self.channels.removeValue(forKey: (channel?.parent.index)!)
                if self.selectedReaderIndex == self.channel?.parent.index {
                    self.setAtrText("")
                    self.channel = nil
                    setIccPowerButtonLabel(IccPower.reconnect)
                }
            }
        }
    }
    
    func onCardDidConnect(channel: SCardChannel?, error: Error?) {
        log.add("onCardDidConnect()")
        self.setAtrText("")
        if error != nil {
            setIccPowerButtonLabel(.error)
            if (self.readers == nil) {
                Utilities.showOkMessageBox(on: self, message: "Error while connecting to the card", title: "Error")
                return
            }
            if (self.readers.slotError == 0xFE && self.readers.slotStatus == 0x41) {
                Utilities.showOkMessageBox(on: self, message: "Card Mute, please eject it and insert it.", title: "Warning")
                if (!self.stopOnError) {
                    return
                }
            }
            if (self.stopOnError) {
                showErrorAndGoBack(error)
            }
            return
        }
        
        guard let channel = channel else {
            Utilities.showOkMessageBox(on: self, message: "Channel is nil!", title: "Error")
            return
        }
        
        let channelParentIndex: Int = channel.parent.index
        self.channels[channelParentIndex] = channel
        if channelParentIndex == self.selectedReaderIndex {
            self.channel = channel
        }
        
        self.channel = channel
        self.channel = channel
        self.setAtrText(channel.atr.hexa)
        setIccPowerButtonLabel(IccPower.on)
    }
    
    private func onReaderListDidCloseNext(_ error: Error?) {
        if error != nil {
            showErrorAndGoBack(error)
        } else {
            showErrorAndGoBack(message: "Communication closed", title: "disconnection")
        }
    }
    
    func onReaderListDidClose(readers: SCardReaderList?, error: Error?) {
        log.add("onReaderListDidClose()")
        self.readers = nil
        self.reader = nil
        self.channel = nil

        if !didHidePleaseWait {
            Utilities.hidePleaseWait(on: self, afterHide: {
            	self.didHidePleaseWait = true
                self.onReaderListDidCloseNext(error)
            })
        } else {
            onReaderListDidCloseNext(error)
        }
    }
    
    // The reader object is created correctly or there is an error
    func onReaderListDidCreate(readers: SCardReaderList?, error: Error?) {
        log.add("onReaderListDidCreate()")
        Utilities.hidePleaseWait(on: self)
        didHidePleaseWait = true
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        guard let readers = readers else {
            showErrorAndGoBack(message: "Readers is nil!", title: "Error")
            return
        }
        
        self.readers = readers
        setConnectionStateLabel("Connected")
        
        communicationMode = .control
        selectedActionIndex = 0
        selectedReaderIndex = 0
        
        guard let reader = readers.getReader(slot: selectedReaderIndex) else {
            showErrorAndGoBack(message: "Asking for reader 0 returned nil", title: "Error")
            return
        }
        
        self.reader = reader
        selectedActionName = readers.slots[selectedReaderIndex]
        
        if reader.cardPresent {
            reader.cardConnect()
        }
        
        setSlotsButtonState()
        setSlotbuttonLabel(selectedActionName)
        
        if reader.cardPresent {
            if reader.cardPowered {
                setIccPowerButtonLabel(IccPower.on)
            } else {
                setIccPowerButtonLabel(IccPower.off)
            }
        } else {
            setIccPowerButtonLabel(IccPower.none)
        }
    }
    
    // When the reader wake up or go to sleep
    func onReaderListState(readers: SCardReaderList, isInLowPowerMode: Bool) {
        log.add("onReaderListState()")
        self.isSleeping = isInLowPowerMode
        if isInLowPowerMode {
            log.add("The reader is going to sleep")
            disableUI()
            setDeviceTitle(true)
        } else {
            log.add("The reader is waking up")
            enableUI()
            setDeviceTitle()
        }
    }
    
    // When we get battery info
    func onPowerInfo(powerState: Int?, batteryLevel: Int?, error: Error? ) {
        log.add("onPowerInfo()")
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        guard let powerState = powerState else {
            showErrorAndGoBack(message: "Error, powerState is nil", title: "Error")
            return
        }
        
        guard let batteryLevel = batteryLevel else {
            showErrorAndGoBack(message: "Error, batteryLevel is nil", title: "Error")
            return
        }
        
        let message = "Power state: \(powerState), Battery Level: \(batteryLevel)"
        Utilities.showOkMessageBox(on: self, message: message, title: "Battery level", afterShowing: {
            ()
        })
    }
}
