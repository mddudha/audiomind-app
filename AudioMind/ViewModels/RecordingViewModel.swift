//
//  RecordingViewModel.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import Foundation
import Combine
import SwiftData
import UIKit
import AVFAudio

@MainActor
final class RecordingViewModel: ObservableObject {
    enum RecordingState {
        case notRecording
        case recording
        case paused
    }

    @Published var recordingState: RecordingState = .notRecording
    @Published var isRecording = false
    @Published var timerText: String = "00:00"
    @Published var error: String? = nil
    @Published var transcripts: [String] = []
    private let transcriptionService = TranscriptionService()

    
    private var recorder = AudioRecorderService()
    
    private var timer: Timer?
    private var secondsElapsed = 0
    
    private var shouldResumeAfterInterruption: Bool {
        !isRecording && UIApplication.shared.applicationState == .active
    }

    
    init() {
        recorder = AudioRecorderService()

        // Handle 30s audio segment
        recorder.onSegmentSaved = { [weak self] url in
            self?.handleSegmentSaved(at: url)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        recorder.$isRecording
            .receive(on: RunLoop.main)
            .assign(to: &$isRecording)
    }
    
    private func pauseTimer() {
        timer?.invalidate()
    }

    func handleSegmentSaved(at fileURL: URL) {
        transcriptionService.transcribeAudio(at: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcript):
                    self?.transcripts.append(transcript)
                    print("✅ Transcribed:", transcript)
                case .failure(let error):
                    print("❌ Failed transcription:", error.localizedDescription)
                }
            }
        }
    }

    
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            print("📴 Interruption began")
            pauseRecording()
            pauseTimer()
            recordingState = .paused

        case .ended:
            print("📲 Interruption ended")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                if shouldResumeAfterInterruption {
                    resumeRecording()
                    startTimer()
                    recordingState = .recording
                }
            } catch {
                print("❌ Could not resume recording: \(error)")
                self.error = "Failed to resume after interruption"
            }

        default:
            break
        }
    }

    
    private func pauseRecording() {
        recorder.pauseRecording()
    }

    private func resumeRecording() {
        do {
            try recorder.resumeRecording()
            startTimer()
            print("▶️ Resumed recording after interruption")
        } catch {
            self.error = "Failed to resume recording: \(error.localizedDescription)"
        }
    }

    
    func toggleRecording(context: ModelContext?) {
        switch recordingState {
        case .notRecording:
            do {
                try recorder.startRecording()
                startTimer()
                recordingState = .recording
            } catch {
                self.error = "Failed to start recording: \(error.localizedDescription)"
            }

        case .recording:
            stopRecording(context: context)
            recordingState = .notRecording

        case .paused:
            do {
                try recorder.resumeRecording()
                startTimer()
                recordingState = .recording
            } catch {
                self.error = "Failed to resume recording: \(error.localizedDescription)"
            }
        }
    }

    
    func stopRecording(context: ModelContext?) {
        recorder.stopRecording()
        stopTimer()

        guard let context, let url = recorder.getRecordingURL() else {
            print("Missing context or URL")
            return
        }

        let session = RecordingSession(fileURL: url, duration: secondsElapsed)
        context.insert(session)

        do {
            try context.save()
            print("✅ Recording saved to SwiftData")
        } catch {
            print("❌ Error saving session: \(error)")
        }
    }
    
    private func startTimer() {
//        secondsElapsed = 0
        updateTimerText()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.secondsElapsed += 1
                self.updateTimerText()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerText = "00:00"
    }
    
    private func updateTimerText() {
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        timerText = String(format: "%02d:%02d", minutes, seconds)
    }
}
