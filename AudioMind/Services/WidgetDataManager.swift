//
//  WidgetDataManager.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults: UserDefaults
    private let isRecordingKey = "isRecording"
    private let sessionCountKey = "sessionCount"
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: "group.com.mirva.AudioMind") ?? UserDefaults.standard
    }
    
    var isRecording: Bool {
        get {
            return userDefaults.bool(forKey: isRecordingKey)
        }
        set {
            userDefaults.set(newValue, forKey: isRecordingKey)
        }
    }
    
    func getSessionCount() -> Int {
        return userDefaults.integer(forKey: sessionCountKey)
    }
    
    func updateSessionCount(_ count: Int) {
        userDefaults.set(count, forKey: sessionCountKey)
    }
    
    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
} 
