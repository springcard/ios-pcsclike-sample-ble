/*
 Copyright (c) 2018-2019 SpringCard - www.springcard.com
 All right reserved
 This software is covered by the SpringCard SDK License Agreement - see LICENSE.txt
 */
import Foundation

class Models {
    private var _models = [Apdu]()
    private var _currentIndex = -1
    private var log: Log!
    private static var instance: Models?
    
    static func getInstance(withNsLog: Bool = true) -> Models {
        if self.instance == nil {
            self.instance = Models()
        }
        return self.instance!
    }
    
    public subscript(_ index: Int) -> Apdu? {
        if index < 0 || index >= self._models.count {
            return nil
        }
        _currentIndex = index
        return self._models[index]
    }
    
    func isEmpty() -> Bool {
        return self._models.isEmpty
    }
    
    func count() -> Int? {
        return self._models.count
    }
    
    private init() {
        self.log = Log.getInstance()
        setInitialContent()
    }
    
    func next() -> Apdu {
        _currentIndex += 1
        if _currentIndex >= self._models.count {
            _currentIndex = 0
        }
        return _models[_currentIndex]
    }
    
    func setInitialContent() {
        /*
        _models.append(Apdu(apdu: "00 A4 04 00 0E 31 50 41 59 2E 53 59 53 2E 44 44 46 30 31 00", type: 0))
        _models.append(Apdu(apdu: "00 A4 04 00 07 A0 00 00 00 42 10 10 00", type: 0))
        _models.append(Apdu(apdu: "80 A8 00 00 02 83 00 00", type: 0))
        _models.append(Apdu(apdu: "80 CA 9F 36 00", type: 0))
        _models.append(Apdu(apdu: "80 CA 9F 13 00", type: 0))
        _models.append(Apdu(apdu: "80 CA 9F 17 00", type: 0))
        _models.append(Apdu(apdu: "80 CA 9F 4D 00", type: 0))
        _models.append(Apdu(apdu: "80 CA 9F 4F 00", type: 0))
        _models.append(Apdu(apdu: "00 B2 01 0C 00", type: 0))
        _models.append(Apdu(apdu: "ff:ca:fa:00", type: 0))  // Card' ATR
        _models.append(Apdu(apdu: "589F", type: 1))  // Wink
 */
        _models.append(Apdu(apdu: "582002", type: 1))  // Product's name
        _models.append(Apdu(apdu: "582001", type: 1))  // Vendor's name
        _models.append(Apdu(apdu: "FF CA 00 00 00", type: 0))  // Get UID
    }
    
    func loadModelsAsync() {
        let urlString = "https://models.springcard.com/api/models/"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                self.log.add("Error while loading online models")
                self.log.add(error?.localizedDescription ?? "No description found")
                return
            }
            
            guard let data = data else {
                self.log.add("Error while getting received data from the REST server")
                return
            }
            do {
                let modelsData = try JSONDecoder().decode([Apdu].self, from: data)
                DispatchQueue.main.async {
                    self._models.removeAll()
                    self._models = modelsData
                    //print(modelsData[1])
                }
            } catch let jsonError {
                self.log.add("Error with received Json from the REST server")
                self.log.add(jsonError.localizedDescription)
            }
        }.resume()
    }
}
