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
import SwiftUICore
import Accelerate
import WidgetKit

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
    @Published var waveformLevels: [Float] = Array(repeating: 0, count: 50)
    private let waveformLength = 50
    private let transcriptionService = TranscriptionService()

    
    var recorder = AudioRecorderService()
    
    private var timer: Timer?
    private var secondsElapsed = 0
    
    private var currentSession: RecordingSession? // Track the current session
    private var currentContext: ModelContext? // Store the context for segment creation
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var shouldResumeAfterInterruption: Bool {
        !isRecording && UIApplication.shared.applicationState == .active
    }
    
    // MARK: - Widget Communication
    private let widgetDataManager = WidgetDataManager.shared

    
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
        // Listen to audioLevel changes and update waveformLevels
        recorder.$audioLevel
            .receive(on: RunLoop.main)
            .sink { [weak self] level in
                guard let self = self else { return }
                self.waveformLevels.append(level)
                if self.waveformLevels.count > self.waveformLength {
                    self.waveformLevels.removeFirst(self.waveformLevels.count - self.waveformLength)
                }
            }
            .store(in: &cancellables)
    }
    
    private func pauseTimer() {
        timer?.invalidate()
    }

    func handleSegmentSaved(at fileURL: URL) {
        guard let session = currentSession, let context = currentContext else { 
            print("❌ Missing session or context for segment")
            return 
        }
        
        // Create the segment and insert it into the context
        let segment = TranscriptionSegment(timestamp: Date(), status: .pending, text: nil, session: session)
        context.insert(segment)
        session.segments.append(segment)
        
        // Save the context immediately after creating the segment
        do { 
            try context.save() 
            print("✅ Segment created and saved to context")
        } catch { 
            print("❌ Error saving segment: \(error)") 
        }

        // Now transcribe the audio
        transcriptionService.transcribeAudio(at: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcript):
                    segment.text = transcript
                    segment.status = .completed
                    self?.transcripts.append(transcript)
                    print("✅ Transcribed and updated segment: \(transcript)")
                case .failure(let error):
                    segment.status = .failed
                    print("❌ Failed transcription: \(error.localizedDescription)")
                }
                
                // Save context after updating the segment
                if let context = self?.currentContext {
                    do { 
                        try context.save() 
                        print("✅ Context saved after transcription")
                    } catch { 
                        print("❌ Error saving context after transcription: \(error)") 
                    }
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
                secondsElapsed = 0 // Reset timer when starting new recording
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
                let fileName = "Recording-\(dateFormatter.string(from: Date())).caf"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                let session = RecordingSession(fileURL: fileURL)
                currentSession = session
                currentContext = context // Store the context
                if let context = context {
                    context.insert(session)
                    try context.save() // Save the session immediately
                }
                try recorder.startRecording()
                startTimer()
                recordingState = .recording
                
                // Update widget
                widgetDataManager.isRecording = true
                widgetDataManager.refreshWidget()
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
        recordingState = .notRecording
        
        // Update widget
        widgetDataManager.isRecording = false
        updateWidgetSessionCount(context: context)
        widgetDataManager.refreshWidget()
        
        guard let context, let url = recorder.getRecordingURL(), let session = currentSession else {
            print("Missing context, URL, or session")
            stopTimer()
            return
        }
        
        session.fileURL = url
        do {
            try context.save()
            print("✅ Recording saved to SwiftData")
        } catch {
            print("❌ Error saving session: \(error)")
        }
        stopTimer()
        currentSession = nil
        currentContext = nil // Clear context when recording stops
    }
    
    private func startTimer() {
        secondsElapsed = 0 // Always reset timer when starting
        updateTimerText()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState == .recording else { return }
            self.secondsElapsed += 1
            self.updateTimerText()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        secondsElapsed = 0
        timerText = "00:00"
    }
    
    private func updateTimerText() {
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        timerText = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Widget Helper Methods
    private func updateWidgetSessionCount(context: ModelContext?) {
        guard let context = context else { return }
        
        do {
            let descriptor = FetchDescriptor<RecordingSession>()
            let sessions = try context.fetch(descriptor)
            widgetDataManager.updateSessionCount(sessions.count)
        } catch {
            print("❌ Error fetching session count for widget: \(error)")
        }
    }
    
    func initializeWidgetData(context: ModelContext?) {
        updateWidgetSessionCount(context: context)
        widgetDataManager.isRecording = isRecording
        widgetDataManager.refreshWidget()
    }
}
