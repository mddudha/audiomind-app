//
//  TranscriptionService.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/3/25.
//

import Foundation

final class TranscriptionService {
 
      private let endpoint = URL(string: "http://10.0.0.105:8888/transcribe")!
    
    func transcribeAudio(at url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        func attemptTranscription(retryCount: Int = 0) {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"

            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            guard let audioData = try? Data(contentsOf: url) else {
                completion(.failure(NSError(domain: "AudioError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio data not found"])))
                return
            }

            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.caf\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/x-caf\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Transcription attempt \(retryCount + 1) failed:", error.localizedDescription)
                    if retryCount < 2 {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                            attemptTranscription(retryCount: retryCount + 1)
                        }
                    } else {
                        completion(.failure(error))
                    }
                    return
                }

                guard let data = data else {
                    print("❌ No data received, attempt \(retryCount + 1)")
                    if retryCount < 2 {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                            attemptTranscription(retryCount: retryCount + 1)
                        }
                    } else {
                        completion(.failure(NSError(domain: "TranscriptionError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received after retries"])))
                    }
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let text = json["transcript"] as? String {
                        print("✅ Transcription succeeded on attempt \(retryCount + 1)")
                        completion(.success(text))
                    } else {
                        throw NSError(domain: "TranscriptionError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                    }
                } catch {
                    print("❌ JSON parse error on attempt \(retryCount + 1): \(error.localizedDescription)")
                    if retryCount < 2 {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                            attemptTranscription(retryCount: retryCount + 1)
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
        attemptTranscription()
    }
    
//    // In TranscriptionService.swift
//
//    // You currently have this function, which creates the multipart body
//    // You call this internally now, but it's commented out in your main transcribeAudio.
//    // Let's ensure the main transcribeAudio function uses the correct filename and mimetype.
//
//    func transcribeAudio(at url: URL, completion: @escaping (Result<String, Error>) -> Void) {
//        var request = URLRequest(url: endpoint)
//        request.httpMethod = "POST"
//
//        let boundary = UUID().uuidString
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        guard let audioData = try? Data(contentsOf: url) else {
//            completion(.failure(NSError(domain: "AudioError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio data not found"])))
//            return
//        }
//
//        // --- CHANGE STARTS HERE ---
//        let filename = url.lastPathComponent // Get the actual filename (e.g., UUID.wav)
//        let mimetype: String
//        if url.pathExtension.lowercased() == "wav" {
//            mimetype = "audio/wav"
//        } else if url.pathExtension.lowercased() == "caf" {
//            mimetype = "audio/x-caf" // Keep this for robustness if other files are sent
//        } else {
//            mimetype = "application/octet-stream" // Generic fallback
//        }
//
//        var body = Data()
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
//        body.append(audioData)
//        body.append("\r\n".data(using: .utf8)!)
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        // --- CHANGE ENDS HERE ---
//
//        request.httpBody = body
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("❌ Transcription failed:", error)
//                completion(.failure(error))
//                return
//            }
//
//            // ... (rest of your existing code for handling data, response, and errors) ...
//            guard let data = data else {
//                completion(.failure(NSError(domain: "TranscriptionError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
//                return
//            }
//
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let text = json["transcript"] as? String {
//                    completion(.success(text))
//                } else {
//                    // Add more detailed error info for debugging server response
//                    let rawResponseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
//                    throw NSError(domain: "TranscriptionError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format or missing 'transcript' field. Raw response: \(rawResponseString)"])
//                }
//            } catch {
//                print("❌ JSON parse error: \(error)")
//                print("🔄 Raw response:", String(data: data, encoding: .utf8) ?? "nil")
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//
//    // You can remove or keep the private func createMultipartBody if it's not used elsewhere.
//    // The main transcribeAudio function is now doing the body creation directly.
//
//


    
    private func createMultipartBody(fileURL: URL, boundary: String) -> Data {
        var body = Data()

        let filename = fileURL.lastPathComponent
        let mimetype = "audio/caf" // Prefer .mp3, .wav, or .m4a if supported

        // 1. Add file
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // 2. Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // 3. Close
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }


}
