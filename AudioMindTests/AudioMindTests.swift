//
//  AudioMindTests.swift
//  AudioMindTests
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import Testing
@testable import AudioMind
import Foundation

struct AudioMindTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testRecordingSessionInitialization() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test.caf")
        let session = RecordingSession(fileURL: fileURL)
        #expect(session.fileURL == fileURL)
        #expect(session.segments.isEmpty)
        #expect(session.createdAt.timeIntervalSinceNow < 1) // createdAt is now
    }

    @Test func testTranscriptionSegmentInitialization() async throws {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/test.caf"))
        let now = Date()
        let segment = TranscriptionSegment(timestamp: now, status: .pending, text: nil, session: session)
        #expect(segment.timestamp == now)
        #expect(segment.status == .pending)
        #expect(segment.text == nil)
        #expect(segment.session === session)
    }

    @Test func testAddSegmentToSession() async throws {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/test.caf"))
        let segment = TranscriptionSegment(timestamp: Date(), status: .pending, text: "Hello", session: session)
        session.segments.append(segment)
        #expect(session.segments.count == 1)
        #expect(session.segments.first === segment)
    }

    @Test func testTranscriptionSegmentStatusUpdate() async throws {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/test.caf"))
        let segment = TranscriptionSegment(timestamp: Date(), status: .pending, text: nil, session: session)
        segment.status = .completed
        #expect(segment.status == .completed)
    }

}
