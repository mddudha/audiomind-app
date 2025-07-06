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
    var createdAt: Date
    var fileURL: URL
    @Relationship(deleteRule: .cascade, inverse: \TranscriptionSegment.session)
    var segments: [TranscriptionSegment] = []

    init(fileURL: URL, createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
        self.fileURL = fileURL
    }
}
