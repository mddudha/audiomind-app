//
//  TranscriptionService.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
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
                        completion(.success(text))
                    } else {
                        throw NSError(domain: "TranscriptionError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                    }
                } catch {
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
    
    private func createMultipartBody(fileURL: URL, boundary: String) -> Data {
        var body = Data()

        let filename = fileURL.lastPathComponent
        let mimetype = "audio/caf"

        if let fileData = try? Data(contentsOf: fileURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }


}
