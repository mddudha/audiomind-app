//
//  TranscriptionSegment.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import Foundation
import SwiftData

@Model
class TranscriptionSegment {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var status: SegmentStatus
    var text: String?
    @Relationship var session: RecordingSession?

    init(timestamp: Date = .now, status: SegmentStatus = .pending, text: String? = nil, session: RecordingSession? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.status = status
        self.text = text
        self.session = session
    }
}

enum SegmentStatus: String, Codable, CaseIterable {
    case pending
    case transcribing
    case completed
    case failed
}
