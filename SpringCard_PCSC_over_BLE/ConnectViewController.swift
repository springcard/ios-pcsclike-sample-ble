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
    private var selectedSlotIndex = 0
    private var selectedSlotName = ""
    private var settings = Settings()
    private var log: Log!
    private var debugExchanges = true
    
    private var models = Models()
    
    //var startingTime: DispatchTime!
    //var endingTime: DispatchTime!
    
    // Interface objects *******************************************
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
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var responseLabel: UILabel!
    // *************************************************************
    
    // Internal state **********************************************
    var communicationMode: CommunicationMode = .transmit
    var possibleCommunicationMode: CommunicationMode = .transmit {
        didSet {
            switch possibleCommunicationMode {
            case .control:
                setControlUiOnly()
            case .transmit:
                setTransmitAndControlUi()
            case .none:
                disableCommunicationUi()
            }
        }
    }
    
    private var isConnected = false
    
    // Used to "translate" (hex string to ASCII) RAPDU ********
    var translateState: Bool = false
    var rapduBackup: String = ""
    // ********************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rapdu.text = ""
        debugExchanges = settings.get(key: "debugExchanges")
        self.log = Log.getInstance()
        Utilities.log = self.log
        infoButton.isEnabled = false
        Utilities.showPleaseWait(on: self)
        centralManager.delegate = self
        self.centralManager.connect(self.device!)
        emptyTextFields()
        deviceTitle.title = device?.name ?? "no device name"
        setConnectionStateLabel("Connecting")
        setRapduCapduLookAndFeel()
        addGestures()
        rapdu.text = ""
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
        guard let keyIndex: KeyIndex = KeyIndex(rawValue: UInt8(keyIndexFromSettings + 1)) else {
            return nil
        }
        let debugCommunication: Bool = settings.get(key: "debugSecureCommunication")
        return SecureConnectionParameters(authMode: .Aes128, keyIndex: keyIndex, keyValue: secureKey, commMode: .secure, debugSecureCommunication: debugCommunication)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        //startingTime = DispatchTime.now()
        let secureParameters = getSecureConnectionParameters()
        SCardReaderList.create(peripheral: self.device!, centralManager: self.centralManager, advertisingServices: self.advertisingServices, delegate: self, secureConnectionParameters: secureParameters)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != CBManagerState.poweredOn {
            //Utilities.hidePleaseWait(on: self)
            Utilities.showOkMessageBox(on: self, message: "Please activate Bluetooth", title: "Error")
            goBack()
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
    
    
    // ****************************************************
    // * Manage UI fields (content, state and appearance) *
    // ****************************************************
    
    func setRapduCapduLookAndFeel() {
        let color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        capdu.layer.borderWidth = 1
        capdu.layer.borderColor = color
        rapdu.layer.borderWidth = 1
        rapdu.layer.borderColor = color
    }
    
    // Remove text & label fields who have content
    func emptyTextFields() {
        setCapduLabel(text: "")
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
    
    func _setUiFromCommunication(mode: CommunicationMode) {
        // map to mode.none
        var transmitControlInterruptIsEnabled = false
        var transmitSegmentIsEnabled = false
        var controlSegmentIsEnabled = false
        var iccPowerButtonIsEnabled = false
        
        if mode == .control {
            transmitControlInterruptIsEnabled = true
            transmitSegmentIsEnabled = false
            controlSegmentIsEnabled = true
            iccPowerButtonIsEnabled = false
            transmitControlInterrupt.selectedSegmentIndex = 1
            iccPowerButton.isEnabled = iccPowerButtonIsEnabled
        } else if mode == .transmit {
            transmitControlInterruptIsEnabled = true
            transmitSegmentIsEnabled = true
            controlSegmentIsEnabled = true
            iccPowerButtonIsEnabled = true
            iccPowerButton.isEnabled = true
        }
        transmitControlInterrupt.isEnabled = transmitControlInterruptIsEnabled
        transmitControlInterrupt.setEnabled(transmitSegmentIsEnabled, forSegmentAt: 0)
        transmitControlInterrupt.setEnabled(controlSegmentIsEnabled, forSegmentAt: 1)
    }
    
    // When there's no card but we are connected to the reader
    func setControlUiOnly() {
        _setUiFromCommunication(mode: .control)
    }
    
    // When a card is connected (and powered)
    func setTransmitAndControlUi() {
        _setUiFromCommunication(mode: .transmit)
    }
    
    // Should not happen
    func disableCommunicationUi() {
        _setUiFromCommunication(mode: .none)
    }
    
    func setRunButtonAccordingToCurrentState(requestedMode: CommunicationMode) {
        runButton.isEnabled = true
        if requestedMode == .transmit && possibleCommunicationMode == .control {
            runButton.isEnabled = false
        }
        if possibleCommunicationMode == .none {
            runButton.isEnabled = false
        }
    }
    
    func setAtrLabel(_ value: String) {
        self.atrLabel.text = value
    }
    
    func setCapduLabel(text: String) {
        self.capdu.text = text
    }
    
    func setRapdu(text: String) {
        self.rapdu.text += text + "\n"
    }
    
    func setRapdu(bytes: [UInt8]) {
        setRapdu(text: bytes.hexa)
    }
    
    func setSegmentCommunicationMode(_ communicationMode: CommunicationMode) {
        if self.possibleCommunicationMode == .control && communicationMode == .transmit {
            return
        }
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
    
    /// On lui passe le statut courant pour qu'il affiche le prochain statut possible
    func setIccPowerButtonLabel(_ state: IccPower) {
        let label: String
        switch state {
        case .none:
            label = ""
        case .off:
            label = "Connect"
        case .on:
            label = "Disconnect"
        case .reconnect:
            label = "reconnect"
        }
        //let label = (state == .off) ? "Connect" : (state == .on) ? "Disconnect" : ""
        iccPowerButton.setTitle(label, for: .normal)
    }
    
    // ********************************************
    // * UI Actions (buttons and segments clicks) *
    // ********************************************
    
    @IBAction func onModelsClick(_ sender: UIButton) {
        let model = models.next()
        setCapduLabel(text: model.apdu)
        setRunButtonAccordingToCurrentState(requestedMode: model.type)
        setSegmentCommunicationMode(model.type)
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
    
    @IBAction func onPreviousApduClick(_ sender: Any) {
        // TODO
    }
    
    @IBAction func onNextApduClick(_ sender: Any) {
        // TODO
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
        //setRapdu(text: "")
        translateState = false
        if self.communicationMode == .transmit {
            if self.channel == nil {
                Utilities.showOkMessageBox(on: self, message: "Channel is nil", title: "Error")
                return
            }
        } else {
            if self.reader == nil {
                Utilities.showOkMessageBox(on: self, message: "Reader is nil", title: "Error")
                return
            }
        }
        let parser = ApduParser(capdu.text)
        if !parser.hasContent() {
            Utilities.showOkMessageBox(on: self, message: "There's no content to send", title: "Warning")
            return
        }
        guard let apdu = parser.getFirstLine() else {
            Utilities.showOkMessageBox(on: self, message: "ADPU is invalid", title: "Error")
            return
        }
        if self.communicationMode == .transmit {
            self.channel?.transmit(command: apdu)
        } else {
            self.reader?.control(command: apdu)
        }
    }
    
    func showSlotSelectionActionSheet(slots: [String], afterConfirm: (() -> ())? = nil) {
        let slotsMenu = UIAlertController(title: "Select slot:", message: nil, preferredStyle: .actionSheet)
        slotsMenu.modalPresentationStyle = .popover
        
        for (index, slot) in slots.enumerated() {
            let slotAction = UIAlertAction(title: slot, style: .default, handler: { action in
                if let action = afterConfirm {
                    self.selectedSlotName = slot
                    self.selectedSlotIndex = index
                    action()
                }
            })
            slotsMenu.addAction(slotAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        slotsMenu.addAction(cancelAction)
        
        if let presenter = slotsMenu.popoverPresentationController {
            presenter.sourceView = slotButton
            presenter.sourceRect = slotButton.bounds
        }
        self.present(slotsMenu, animated: true, completion: nil)
    }
    
    @IBAction func onSlotClick(_ sender: Any) {
        var slots = [String]()
        for slot in self.readers.slots {
            slots.append(slot)
        }
        showSlotSelectionActionSheet(slots: slots, afterConfirm: {
            guard let reader = self.readers.getReader(slot: self.selectedSlotIndex) else {
                let message = "Getting reader returned nil"
                self.log.add("Error: " + message)
                return
            }
            
            self.reader = reader
            self.setSlotbuttonLabel(self.selectedSlotName)
            
            if reader.cardPresent {
                if !reader.cardPowered {
                    reader.cardConnect()
                } else {
                    self.setIccPowerButtonLabel(IccPower.on)
                }
            } else {
                self.setIccPowerButtonLabel(IccPower.none)
            }
        })
    }
    
    @IBAction func onPowerOnOffClick(_ sender: Any) {
        guard let reader = self.reader else {
            return
        }
        if self.channel != nil {
            log.add("Debug: Request to disconnect from card via the channel")
            channel?.cardDisconnect()
        } else {
            log.add("Debug: Request to connect to the card via the reader")
            reader.cardConnect()
        }
    }
    
    @IBAction func onCommunicationModeChange(_ sender: Any) {
        let segmentTitle = Utilities.getSegmentedControlLabel(self.transmitControlInterrupt)
        if segmentTitle == nil {
            return
        }
        if segmentTitle!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "transmit" {
            self.communicationMode = .transmit
        } else {
            self.communicationMode = .control
        }
    }
    
    // **************
    // * Misc funcs *
    // **************
    
    func goBack() {
        //Utilities.hidePleaseWait(on: self)
        _ = navigationController?.popViewController(animated: false)
    }
    
    func showErrorAndGoBack(_ error: Error?) {
        //Utilities.hidePleaseWait(on: self)
        if error != nil {
            let errorCode = error?._code ?? 0
            Utilities.showOkMessageBox(on: self, message: String(errorCode) + ": " + error.debugDescription, title: "Error")
            goBack()
        }
    }
    
    // ********************
    // ********************
    // * Lib's Callbacks  *
    // ********************
    // ********************
    func onReaderStatus(reader: SCardReader?, present: Bool?, powered: Bool?, error: Error?) {
        log.add("onReaderStatus()")
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        guard let reader = reader else {
            Utilities.showOkMessageBox(on: self, message: "reader is nil and error is not nil!!", title: "Error")
            readers.close()
            goBack()
            return
        }
        
        possibleCommunicationMode = .control
        if present != nil && powered != nil {
            if (present! && powered!) && reader == self.reader {
                possibleCommunicationMode = .transmit
            }
        }
        
        if self.reader != reader {
            log.add("ConnectViewController: Not the same reader")
            return
        }
        self.reader = reader
        if reader.cardPresent {
            log.add("ConnectViewController: CARD PRESENT")
            if !reader.cardPowered {
                reader.cardConnect()
            } else {
                setIccPowerButtonLabel(IccPower.on)
            }
        } else {
            setIccPowerButtonLabel(IccPower.none)
            log.add("ConnectViewController: CARD ABSENT")
            possibleCommunicationMode = .control
        }
    }
    
    // When we are getting an answer from the card
    func onTransmitDidResponse(channel: SCardChannel?, response: [UInt8]?, error: Error?) {
        log.add("onTransmitDidResponse()")
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        guard let bytes = response else {
            Utilities.showOkMessageBox(on: self, message: "Response is nil", title: "Warning")
            return
        }
        possibleCommunicationMode = .transmit
        if bytes.count <= 2 {
            //setRapdu(text: "")
            setStatusWordLabel(bytes)
        } else {
            let index = (bytes.count - 2)
            let swBytes = (Array(bytes[index...]))
            setRapdu(text: bytes.hexa)
            setStatusWordLabel(swBytes)
        }
    }
    
    // When we are getting an answer from the reader
    func onControlDidResponse(readers: SCardReaderList?, response: [UInt8]?, error: Error?) {
        log.add("onControlDidResponse()")
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        guard let bytes = response else {
            Utilities.showOkMessageBox(on: self, message: "Response is nil", title: "Warning")
            return
        }
        setStatusWordLabel("")
        setRapdu(text: bytes.hexa)
    }
    
    func onCardDidDisconnect(channel: SCardChannel?, error: Error?) {
        log.add("onCardDidDisconnect()")
        self.channel = nil
        self.setAtrLabel("")
        
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        communicationMode = .control
        possibleCommunicationMode = .control
        setRunButtonAccordingToCurrentState(requestedMode: .control)
        setConnectionStateLabel("Card disconnected")
        setIccPowerButtonLabel(IccPower.reconnect)
    }
    
    func onCardDidConnect(channel: SCardChannel?, error: Error?) {
        log.add("onCardDidConnect()")
        self.setAtrLabel("")
        if error != nil {
            setConnectionStateLabel("Error")
            showErrorAndGoBack(error)
            return
        }
        
        guard let channel = channel else {
            Utilities.showOkMessageBox(on: self, message: "Channel is nil!", title: "Error")
            return
        }
        
        self.channel = channel
        possibleCommunicationMode = .transmit
        setRunButtonAccordingToCurrentState(requestedMode: .transmit)
        self.channel = channel
        setConnectionStateLabel("Card powered")
        self.setAtrLabel(channel.atr.hexa)
        self.setTransmitAndControlUi()
        setIccPowerButtonLabel(IccPower.on)
    }
    
    func onReaderListDidClose(readers: SCardReaderList?, error: Error?) {
        log.add("onReaderListDidClose()")
        self.readers = nil
        self.reader = nil
        self.channel = nil
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        possibleCommunicationMode = .none
        //goBack()
    }
    
    func onReaderListDidCreate(readers: SCardReaderList?, error: Error?) {
        log.add("onReaderListDidCreate()")
        Utilities.hidePleaseWait(on: self)
        if error != nil {
            showErrorAndGoBack(error)
            return
        }
        
        guard let readers = readers else {
            Utilities.showOkMessageBox(on: self, message: "readers is nil!", title: "Error")
            goBack()
            return
        }
        infoButton.isEnabled = true
        self.readers = readers
        setConnectionStateLabel("Connected")
        
        communicationMode = .control
        possibleCommunicationMode = .control
        //Utilities.showOkMessageBox(on: self, message: nil, title: "Connection is OK")
        
        selectedSlotIndex = 0
        
        guard let reader = readers.getReader(slot: selectedSlotIndex) else {
            Utilities.showOkMessageBox(on: self, message: "Asking for reader 0 returned nil", title: "Error")
            goBack()
            return
        }
        
        self.reader = reader
        selectedSlotName = readers.slots[selectedSlotIndex]
        
        self.setSegmentCommunicationMode(CommunicationMode.transmit)
        if (self.reader?.cardPresent)! {
            self.reader?.cardConnect()
        }
        
        setSlotsButtonState()
        setSlotbuttonLabel(selectedSlotName)
        
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
    
    func onData(characteristicId: String, direction: String, data: [UInt8]?) {
        if !debugExchanges {
            return
        }
        let bytes = data?.hexa ?? "nil"
        let characId = (characteristicId.count > 4) ? "..." + characteristicId.suffix(6) : characteristicId
        setRapdu(text: direction + " " + characId + ": " + bytes)
        log.add(direction + " " + characteristicId + ": " + bytes)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "informationSegue" {
            log.add("Moving to information screen")
            if let readersDiscovered = self.readers {
                let destinationViewControler = segue.destination as! InformationViewController
                destinationViewControler.readers = readersDiscovered
            }
        }
    }
}
