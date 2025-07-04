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

    init(timestamp: Date = .now, status: SegmentStatus = .pending, text: String? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.status = status
        self.text = text
    }
}

enum SegmentStatus: String, Codable, CaseIterable {
    case pending
    case transcribing
    case completed
    case failed
}
