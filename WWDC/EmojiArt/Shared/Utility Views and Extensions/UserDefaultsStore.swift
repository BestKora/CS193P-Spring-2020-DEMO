//
//  UserDefaultsStore.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// an ObservableObject
// which puts/gets an Array of Codable things into/out of UserDefaults

class UserDefaultsStore<DataElement>: ObservableObject where DataElement: Codable
{
    private(set) var key: String
    private var rawData: Data?
    private var _data = [DataElement]()
    private var observer: NSObjectProtocol?

    init(key: String, defaultData: [DataElement] = [], watchForChanges: Bool = false) {
        self.key = "UserDefaultsStore." + key
        if !updateFromUserDefaults() {
            data = defaultData
        }
        if watchForChanges {
            observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: UserDefaults.standard,
                queue: .main
            ) { notification in
                self.updateFromUserDefaults()
            }
        }
    }

    var data: [DataElement] {
        get { _data }
        set {
            _data = newValue
            if let encoded = try? JSONEncoder().encode(newValue) {
                rawData = encoded
                UserDefaults.standard.set(rawData, forKey: key)
            }
            objectWillChange.send()
        }
    }

    @discardableResult
    private func updateFromUserDefaults() -> Bool {
        let newRawData = UserDefaults.standard.data(forKey: key)
        if newRawData != nil, newRawData != rawData {
            if let decoded = try? JSONDecoder().decode([DataElement].self, from: newRawData!) {
                _data = decoded
                rawData = newRawData
                objectWillChange.send()
                return true
            } else {
                // no error handling (yet)
            }
        }
        return false
    }
}
