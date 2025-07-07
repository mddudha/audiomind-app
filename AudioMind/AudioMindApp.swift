//
//  AudioMindApp.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import SwiftUI
import SwiftData
import UIKit

extension Notification.Name {
    static let startRecording = Notification.Name("startRecording")
    static let stopRecording = Notification.Name("stopRecording")
}

@main
struct AudioMindApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecordingSession.self,
            TranscriptionSegment.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.mirva.AudioMind")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RecordingView()
                .onOpenURL { url in
                    handleWidgetURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "audiomind" else { return }
        
        let action = url.host ?? ""
        switch action {
        case "start":
            NotificationCenter.default.post(name: .startRecording, object: nil)
        case "stop":
            NotificationCenter.default.post(name: .stopRecording, object: nil)
        default:
            break
        }
    }
}
