//
//  RecordingView.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = RecordingViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.isRecording ? "Recording…" : "Tap to Record")
                .font(.title2)
                .bold()

            Text(viewModel.timerText)
                .font(.system(.title, design: .monospaced))
                .padding(.bottom, 12)


            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording(context: context)
                } else {
                    viewModel.toggleRecording(context: context)
                }
            }) {
                Image(systemName: {
                    switch viewModel.recordingState {
                    case .notRecording:
                        return "mic.circle.fill"
                    case .recording:
                        return "stop.circle.fill"
                    case .paused:
                        return "pause.circle.fill"
                    }
                }())
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor({
                    switch viewModel.recordingState {
                    case .recording: return .red
                    case .paused: return .orange
                    case .notRecording: return .blue
                    }
                }())
                .padding()
            }

            Spacer()
        }
        .padding()
        .alert(item: Binding(
            get: {
                viewModel.error.map { RecordingErrorMessage(message: $0) }
            },
            set: { _ in viewModel.error = nil }
        )) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
}

private struct RecordingErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    RecordingView()
}

