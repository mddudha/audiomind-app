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
    private var accumulatedFrames: AVAudioFramePosition = 0
    private var chunkTimer: Timer?
    private var segmentIndex = 0
    var onSegmentSaved: ((URL) -> Void)?

    private let transcriptionService = TranscriptionService()

    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    
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
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .oldDeviceUnavailable:
            stopRecording()
        case .newDeviceAvailable:
            break
        default:
            break
        }
    }
    
    private func startChunkTimer() {
        chunkTimer?.invalidate()

        chunkTimer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.flushSegmentToDisk()
        }

        if let chunkTimer = chunkTimer {
            RunLoop.main.add(chunkTimer, forMode: .common)
        }
    }


    private func flushSegmentToDisk() {
        guard let bufferToFlush = currentRecordingBuffer, bufferToFlush.frameLength > 0 else {
            return
        }

        let segmentFilename = "segment_\(segmentIndex).caf"
        let segmentURL = FileManager.default.temporaryDirectory.appendingPathComponent(segmentFilename)

        do {
            let file = try AVAudioFile(forWriting: segmentURL, settings: bufferToFlush.format.settings)
            try file.write(from: bufferToFlush)

            
            bufferToFlush.frameLength = 0
            accumulatedFrames = 0

            convertToWav(sourceURL: segmentURL) { [weak self] wavURL in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let wavURL = wavURL {
                        self.onSegmentSaved?(wavURL)
                    } else {
                        print("Failed to convert segment to WAV")
                    }

                    self.segmentIndex += 1
                }
            }

        } catch {
            print("Failed to write segment: \(error)")
        }
    }
    
    private func convertToWav(sourceURL: URL, completion: @escaping (URL?) -> Void) {
        Task {
            let asset = AVURLAsset(url: sourceURL)
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                completion(nil)
                return
            }

            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
            exporter.outputURL = outputURL
            exporter.outputFileType = .wav

            do {
                try await exporter.export()
                completion(outputURL)
            } catch {
                completion(nil)
            }
        }
    }

    
    func pauseRecording() {
        engine.pause()
    }

    func resumeRecording() throws {
        try engine.start()
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
        let secondsPerSegment: Double = 30.0
        let sampleRate = inputFormat.sampleRate
        let framesPerSegment = AVAudioFrameCount(sampleRate * secondsPerSegment) + inputFormat.channelCount * 1024

        currentRecordingBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: framesPerSegment)
        guard let currentRecordingBuffer = currentRecordingBuffer else {
            throw NSError(domain: "AudioRecordingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create recording buffer."])
        }

        currentRecordingBuffer.frameLength = 0
        accumulatedFrames = 0

        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            guard let currentBuffer = self.currentRecordingBuffer else { return }

      
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
            let level = min(max(rms * 10, 0), 1)
            DispatchQueue.main.async {
                self.audioLevel = level
            }

            let framesAvailable = currentBuffer.frameCapacity - currentBuffer.frameLength
            let framesToCopy = min(buffer.frameLength, framesAvailable)

            if framesToCopy > 0 {
                guard let srcChannelData = buffer.floatChannelData,
                      let dstChannelData = currentBuffer.floatChannelData else {
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

            } else {
                self.flushSegmentToDisk()
            }
        }

        try engine.start()
        isRecording = true
        startChunkTimer()
    }


    func stopRecording() {
        chunkTimer?.invalidate()
        flushSegmentToDisk()

        engine?.stop()
        mixerNode?.removeTap(onBus: 0)
        
        currentRecordingBuffer?.frameLength = 0
        currentRecordingBuffer = nil 
        accumulatedFrames = 0
        
        isRecording = false
    }

    func getRecordingURL() -> URL? {
        return outputURL
    }
}
