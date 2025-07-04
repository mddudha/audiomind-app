//
//  RecordingSession.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import Foundation
import SwiftData

@Model
class RecordingSession {
    @Attribute(.unique) var id: UUID
    var fileURL: URL
    var createdAt: Date
    var duration: Int

    init(fileURL: URL, duration: Int) {
        self.id = UUID()
        self.fileURL = fileURL
        self.createdAt = Date()
        self.duration = duration
    }
}
