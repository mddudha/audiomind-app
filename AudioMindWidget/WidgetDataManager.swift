//
//  WidgetDataManager.swift
//  AudioMindWidget
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
        // Use App Groups UserDefaults for sharing data between app and widget
        self.userDefaults = UserDefaults(suiteName: "group.com.mirva.AudioMind") ?? UserDefaults.standard
    }
    
    // MARK: - Recording State
    var isRecording: Bool {
        get {
            return userDefaults.bool(forKey: isRecordingKey)
        }
        set {
            userDefaults.set(newValue, forKey: isRecordingKey)
        }
    }
    
    // MARK: - Session Count
    func getSessionCount() -> Int {
        return userDefaults.integer(forKey: sessionCountKey)
    }
    
    func updateSessionCount(_ count: Int) {
        userDefaults.set(count, forKey: sessionCountKey)
    }
    
    // MARK: - Widget Refresh
    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
} 