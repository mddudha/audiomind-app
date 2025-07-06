//
//  AudioRecorderService.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import Foundation
import AVFoundation
import Accelerate

final class AudioRecorderService: ObservableObject {
    private var engine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var audioFile: AVAudioFile?
    private var outputURL: URL?

    private var currentRecordingBuffer: AVAudioPCMBuffer?
    private var accumulatedFrames: AVAudioFramePosition = 0 // To keep track of total frames for the segment
    private var chunkTimer: Timer?
    private var segmentIndex = 0
    var onSegmentSaved: ((URL) -> Void)?

    private let transcriptionService = TranscriptionService()

    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0 // 0.0 (silent) to 1.0 (max)
    
    private var format: AVAudioFormat {
        engine.inputNode.inputFormat(forBus: 0)
    }
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )

//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleInterruption),
//            name: AVAudioSession.interruptionNotification,
//            object: nil
//        )
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .oldDeviceUnavailable:
            print("🎧 Headphones unplugged")
            stopRecording()
        case .newDeviceAvailable:
            print("🎧 New audio device connected")
        default:
            break
        }
    }
    
    private func startChunkTimer() {
        chunkTimer?.invalidate()

        chunkTimer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            print("⏱ Timer fired!")
            self?.flushSegmentToDisk()
        }

        if let chunkTimer = chunkTimer {
            RunLoop.main.add(chunkTimer, forMode: .common)
        }
    }


    // In AudioRecorderService.swift

    private func flushSegmentToDisk() {
        print("🧾 Flushing accumulated frames: \(accumulatedFrames)")

        guard let bufferToFlush = currentRecordingBuffer, bufferToFlush.frameLength > 0 else {
            print("No frames to flush.")
            return
        }

        let segmentFilename = "segment_\(segmentIndex).caf"
        let segmentURL = FileManager.default.temporaryDirectory.appendingPathComponent(segmentFilename)

        do {
            let file = try AVAudioFile(forWriting: segmentURL, settings: bufferToFlush.format.settings)
            try file.write(from: bufferToFlush)
            print("✅ Segment saved: \(segmentFilename)")

            // Reset the buffer for the next segment *after* writing
            bufferToFlush.frameLength = 0
            accumulatedFrames = 0

            // Perform WAV conversion
            convertToWav(sourceURL: segmentURL) { [weak self] wavURL in
                guard let self = self else { return }

                DispatchQueue.main.async { // Ensure UI updates or subsequent calls are on main thread if needed
                    if let wavURL = wavURL {
                        print("✅ Converted to WAV:", wavURL)
                        // Call the callback to let the ViewModel handle segment creation and transcription
                        self.onSegmentSaved?(wavURL)
                    } else {
                        print("❌ Failed to convert segment to WAV")
                    }

                    self.segmentIndex += 1
                }
            }

        } catch {
            print("❌ Failed to write segment: \(error)")
        }
    }
    
//
//    private func flushSegmentToDisk() {
//        print("🧾 Flushing accumulated frames: \(accumulatedFrames)") // Changed from bufferQueue.count
//
//        guard let bufferToFlush = currentRecordingBuffer, bufferToFlush.frameLength > 0 else {
//            print("No frames to flush.")
//            return
//        }
//
//        let segmentFilename = "segment_\(segmentIndex).caf"
//        let segmentURL = FileManager.default.temporaryDirectory.appendingPathComponent(segmentFilename)
//
//        do {
//            // Use the format from the buffer itself
//            let file = try AVAudioFile(forWriting: segmentURL, settings: bufferToFlush.format.settings)
//
//            try file.write(from: bufferToFlush) // Write the single accumulated buffer
//
//            print("✅ Segment saved: \(segmentFilename)")
//
//            // Reset the buffer for the next segment *after* writing
//            bufferToFlush.frameLength = 0
//            accumulatedFrames = 0
//
//            // Perform WAV conversion
//            convertToWav(sourceURL: segmentURL) { [weak self] wavURL in
//                guard let self = self else { return }
//
//                DispatchQueue.main.async {
//                    if let wavURL = wavURL {
//                        print("✅ Converted to WAV:", wavURL)
//                        self.onSegmentSaved?(wavURL)
//                    } else {
//                        print("❌ Failed to convert segment to WAV")
//                    }
//
//                    self.segmentIndex += 1
//                }
//            }
//
//        } catch {
//            print("❌ Failed to write segment: \(error)")
//        }
//    }


    // You might need to change this to an async function
    // or call it within a Task {} block from your existing completion handler
    private func convertToWav(sourceURL: URL, completion: @escaping (URL?) -> Void) {
        Task { // Wrap the async code in a Task
            let asset = AVURLAsset(url: sourceURL)
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                print("❌ Could not create export session")
                completion(nil)
                return
            }

            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
            exporter.outputURL = outputURL
            exporter.outputFileType = .wav

            do {
                try await exporter.export() // Use the new async export method
                print("✅ Converted to WAV:", outputURL)
                completion(outputURL)
            } catch {
                print("❌ Failed to convert:", error.localizedDescription) // Use .localizedDescription or toError()
                completion(nil)
            }
        }
    }

    
    func pauseRecording() {
        engine.pause()
        print("⏸ Audio engine paused")
    }

    func resumeRecording() throws {
        try engine.start()
        print("▶️ Audio engine resumed")
    }


    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        engine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()

        engine.attach(mixerNode)
        engine.connect(engine.inputNode, to: mixerNode, format: nil)

        let inputFormat = engine.inputNode.outputFormat(forBus: 0)

        // Calculate capacity for 30 seconds of audio + small buffer
        let secondsPerSegment: Double = 30.0
        let sampleRate = inputFormat.sampleRate
        let framesPerSegment = AVAudioFrameCount(sampleRate * secondsPerSegment) + inputFormat.channelCount * 1024

        // Initialize the accumulating buffer
        currentRecordingBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: framesPerSegment)
        guard let currentRecordingBuffer = currentRecordingBuffer else {
            throw NSError(domain: "AudioRecordingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create recording buffer."])
        }

        currentRecordingBuffer.frameLength = 0
        accumulatedFrames = 0

        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            guard let currentBuffer = self.currentRecordingBuffer else { return }

            // --- Audio Level Calculation ---
            let channelCount = Int(buffer.format.channelCount)
            var rms: Float = 0.0
            if let channelData = buffer.floatChannelData {
                for channel in 0..<channelCount {
                    let data = channelData[channel]
                    let frames = Int(buffer.frameLength)
                    let sum = vDSP.sum(vDSP.square(Array(UnsafeBufferPointer(start: data, count: frames))))
                    rms += sum / Float(frames)
                }
                rms = sqrt(rms / Float(channelCount))
            }
            let level = min(max(rms * 10, 0), 1) // Normalize and clamp
            DispatchQueue.main.async {
                self.audioLevel = level
            }
            // --- End Audio Level Calculation ---

            let framesAvailable = currentBuffer.frameCapacity - currentBuffer.frameLength
            let framesToCopy = min(buffer.frameLength, framesAvailable)

            if framesToCopy > 0 {
                // Manual float32 channel-wise copying
                guard let srcChannelData = buffer.floatChannelData,
                      let dstChannelData = currentBuffer.floatChannelData else {
                    print("❌ Unsupported buffer format for copying")
                    return
                }

                let channelCount = Int(buffer.format.channelCount)

                for channel in 0..<channelCount {
                    let src = srcChannelData[channel]
                    let dst = dstChannelData[channel] + Int(currentBuffer.frameLength)
                    memcpy(dst, src, Int(framesToCopy) * MemoryLayout<Float>.size)
                }

                currentBuffer.frameLength += framesToCopy
                self.accumulatedFrames += AVAudioFramePosition(framesToCopy)

                print("🎙 Appended \(framesToCopy) frames, total: \(currentBuffer.frameLength)")

            } else {
                print("⚠️ Current recording buffer full! Flushing early.")
                self.flushSegmentToDisk()
            }
        }

        try engine.start()
        isRecording = true
        startChunkTimer()
    }


    func stopRecording() {
        chunkTimer?.invalidate()
        flushSegmentToDisk() // Flush any remaining data

        engine?.stop()
        mixerNode?.removeTap(onBus: 0)
        
        // Clear the buffer and reset frames on stop
        currentRecordingBuffer?.frameLength = 0
        currentRecordingBuffer = nil // Release the buffer
        accumulatedFrames = 0
        
        isRecording = false
    }

    func getRecordingURL() -> URL? {
        return outputURL
    }
}
