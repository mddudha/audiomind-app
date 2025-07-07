//
//  AudioMindTests.swift
//  AudioMindTests
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import XCTest
@testable import AudioMind

final class AudioMindTests: XCTestCase {

    func testRecordingSessionInitialization() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.caf")
        let session = RecordingSession(fileURL: fileURL)
        XCTAssertEqual(session.fileURL, fileURL)
        XCTAssertTrue(session.segments.isEmpty)
        XCTAssertLessThan(abs(session.createdAt.timeIntervalSinceNow), 1)
    }

    func testTranscriptionSegmentInitialization() {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/test.caf"))
        let now = Date()
        let segment = TranscriptionSegment(timestamp: now, status: .pending, text: nil, session: session)
        XCTAssertEqual(segment.timestamp, now)
        XCTAssertEqual(segment.status, .pending)
        XCTAssertNil(segment.text)
        XCTAssertTrue(segment.session === session)
    }

    func testAddSegmentToSession() {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/test.caf"))
        let segment = TranscriptionSegment(timestamp: Date(), status: .pending, text: "Hello", session: session)
        session.segments.append(segment)
        XCTAssertEqual(session.segments.count, 1)
        XCTAssertTrue(session.segments.first === segment)
    }

    func testTranscriptionSegmentStatusUpdate() {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/test.caf"))
        let segment = TranscriptionSegment(timestamp: Date(), status: .pending, text: nil, session: session)
        segment.status = .completed
        XCTAssertEqual(segment.status, .completed)
    }

    func testSessionSegmentIntegration() {
        let session = RecordingSession(fileURL: URL(fileURLWithPath: "/tmp/integration.caf"))
        let segment1 = TranscriptionSegment(timestamp: Date(), status: .completed, text: "Hello", session: session)
        let segment2 = TranscriptionSegment(timestamp: Date().addingTimeInterval(1), status: .completed, text: "World", session: session)
        session.segments.append(contentsOf: [segment1, segment2])
        XCTAssertEqual(session.segments.count, 2)
        XCTAssertTrue(session.segments[0].session === session)
        XCTAssertTrue(session.segments[1].session === session)
        XCTAssertEqual(session.segments.map { $0.text ?? "" }.joined(separator: " "), "Hello World")
    }

    func testTranscriptionServiceErrorHandling() {
        let expectation = XCTestExpectation(description: "Error callback")
        let service = TranscriptionService()
        service.transcribeAudio(at: URL(fileURLWithPath: "/path/does/not/exist.caf")) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            case .success:
                XCTFail("Should not succeed")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
