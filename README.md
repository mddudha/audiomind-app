
# AudioMind

**AudioMind** is a production-ready iOS application that records audio, splits it into 30-second segments, and transcribes each segment using a Python FastAPI backend powered by Faster-Whisper. It supports background recording, robust audio session handling, waveform visualization, and persistent storage using SwiftData. AudioMind is optimized for real-world recording scenarios such as interruptions, route changes, and offline recovery.

---

## Features

- Audio recording using AVAudioEngine
- 30-second automatic segmentation of audio streams
- Real-time waveform visualization during recording
- Transcription integration via a FastAPI backend using Faster-Whisper
- SwiftData-based storage of recording sessions and transcript segments
- Background recording support with audio and fetch entitlements
- Route change and audio interruption recovery
- VoiceOver accessibility labels and VoiceOver-ready controls
- Home screen widget to start/stop recording
- Error handling for permission denials, route changes, network failures, and more

---

## Getting Started

This guide includes setup instructions for both the **iOS app** and the **transcription backend**.

---

## iOS App Setup

### Prerequisites

- macOS 13.5+ and Xcode 15+
- Physical iOS device (required for background audio)
- Microphone access permission

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/AudioMind.git
cd AudioMind
````

### 2. Open the Project

```bash
open AudioMind.xcodeproj
```

### 3. Enable App Capabilities

In **Xcode → Signing & Capabilities**:

* **App Groups**
  Add: `group.com.mirva.AudioMind`

* **Background Modes**

  * Enable `Audio, AirPlay, and Picture in Picture`
  * Enable `Background fetch`

* Add to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio.</string>
```

### 4. Run the App

* Connect a physical iPhone
* Select the device in Xcode
* Press **Cmd + R** to build and run

---

## Transcription Backend Setup

The backend is a FastAPI server that uses [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper) for speech-to-text processing.

### Requirements

* Python 3.10+
* pip

### 1. Install Dependencies

From the project root (or `backend/` folder if separated):

```bash
pip install -r requirements.txt
```

### 2. Run the Server

```bash
uvicorn app:app --host 0.0.0.0 --port 8888
```

This starts the server at:

```
http://<your-ip>:8888/transcribe
```

> Make sure the iOS device and the server machine are on the same network. Update the IP address in `TranscriptionService.swift`.

### 3. Endpoint Summary

* **POST** `/transcribe`
* Content-Type: `multipart/form-data`
* Field: `file` (CAF or WAV audio segment)
* Response: `{ "transcript": "..." }`

---

## SwiftData Schema

```swift
@Model
class RecordingSession {
    var id: UUID
    var createdAt: Date
    var fileURL: URL
    var segments: [TranscriptionSegment]
}

@Model
class TranscriptionSegment {
    var id: UUID
    var timestamp: Date
    var status: SegmentStatus  // .pending, .transcribing, .completed, .failed
    var text: String?
    var session: RecordingSession?
}
```

Sessions and segments are saved locally using SwiftData and shared with widgets via the app group.

---

## Screenshots

| Recording Screen                             | Waveform Meter                             | Session History                            | Widget                                 |
| -------------------------------------------- | ------------------------------------------ | ------------------------------------------ | -------------------------------------- |
| ![Recording](docs/screenshots/recording.png) | ![Waveform](docs/screenshots/waveform.png) | ![Sessions](docs/screenshots/sessions.png) | ![Widget](docs/screenshots/widget.png) |

> Place screenshots in the `docs/screenshots/` folder.

---

## Demo

Watch the full walkthrough video:
[YouTube Demo](https://youtube.com/your-demo-link-here)

---

## Folder Structure

```
AudioMind/
├── AudioMindApp.swift
├── Views/
├── ViewModels/
├── Services/
├── Models/
├── Widgets/
├── Tests/
├── backend/
│   ├── app.py
│   └── requirements.txt
├── docs/
│   └── screenshots/
└── README.md
```

---

## Run Tests

### iOS Unit Tests

In Xcode:

* Select Product → Test or press **Cmd + U**

### Backend API Manual Test

```bash
curl -X POST http://localhost:8888/transcribe \
  -F "file=@test.wav"
```

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Author

Developed by **Mirvaben Dudhagara**
[LinkedIn](https://www.linkedin.com/in/mirva-dudhagara)

```
```
