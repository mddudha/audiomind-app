//
//  SessionDetailView.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import SwiftUI
import SwiftData
import os

struct SessionDetailView: View, Identifiable {
    let id = UUID()
    let sessionID: UUID
    var body: some View {
        SessionDetailQueryView(sessionID: sessionID)
    }
}

struct SessionDetailQueryView: View {
    let sessionID: UUID
    @Query private var sessions: [RecordingSession]

    init(sessionID: UUID) {
        self.sessionID = sessionID
        self._sessions = Query(filter: #Predicate<RecordingSession> { $0.id == sessionID })
    }

    var body: some View {
        if let session = sessions.first {
            VStack(alignment: .leading, spacing: 16) {
                Text("Session Details")
                    .font(.title2)
                    .bold()
                Text("Date: \(session.createdAt, formatter: dateFormatter)")

                Divider()

                Text("Transcript:")
                    .font(.headline)
                ScrollView {
                    let transcript = fullTranscript(for: session)
                    
                    Text(transcript.isEmpty ? "No transcript yet." : transcript)
                        .font(.body)
                        .padding(.top, 2)
                        .foregroundColor(transcript.isEmpty ? .secondary : .primary)
                        .padding()
                }
                .frame(maxHeight: 300)
                .onAppear {
                    let transcript = fullTranscript(for: session)
                    let segmentCount = session.segments.count
                }

                Spacer()
            }
            .padding()
        } else {
            Text("Session not found.")
        }
    }

    private func fullTranscript(for session: RecordingSession) -> String {
        session.segments
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap { $0.text }
            .joined(separator: " ")
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .short
    return df
}()
