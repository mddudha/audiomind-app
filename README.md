# AudioMind

**AudioMind** is a production-grade iOS application designed to record audio, segment it into 30-second chunks, and transcribe each segment using a Whisper-based backend. Built using SwiftUI, AVAudioEngine, and SwiftData, the app demonstrates robust audio session handling, real-time waveform monitoring, and scalable data persistence. It also includes widget support for quick access.

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Screenshots](#screenshots)
- [Demo](#demo)
- [Setup Instructions](#setup-instructions)
  - [iOS App](#ios-app)
  - [Transcription Backend](#transcription-backend)
- [SwiftData Schema](#swiftdata-schema)
- [Testing](#testing)
- [Known Issues](#known-issues)
- [Folder Structure](#folder-structure)
- [License](#license)

---

## Features

### Core Functionality
- Audio recording using `AVAudioEngine`
- 30-second automatic audio segmentation
- Backend transcription using [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper)
- Real-time audio waveform visualization
- Background recording support
- Audio route change and interruption handling
- SwiftData-based local persistence for sessions and transcriptions

### Additional Capabilities
- Retry logic with exponential backoff
- WidgetKit integration for quick start/stop recording
- VoiceOver accessibility support
- Session list with search and filtering
- Session detail view with full transcription
- Modular and testable codebase

---

## Architecture Overview

This project follows the MVVM pattern with a reactive Combine-based architecture. Below are the major layers and responsibilities:

- `RecordingViewModel.swift` — business logic, audio session lifecycle, widget syncing
- `AudioRecorderService.swift` — handles recording, AVAudioEngine, audio levels, chunking
- `TranscriptionService.swift` — manages API upload and retry logic
- `SwiftData` — persistent storage of `RecordingSession` and `TranscriptionSegment` models
- `WidgetDataManager.swift` — shared storage and refresh logic for widgets
- `AudioMindWidget` — WidgetKit implementation for small/medium/large quick controls

---

## Screenshots

| Recording Screen | Waveform View | Session List | Widget |
|------------------|---------------|---------------|--------|
| ![Recording Screen](docs/screenshots/recording.png) | ![Waveform](docs/screenshots/waveform.png) | ![Session List](docs/screenshots/sessions.png) | ![Widget](docs/screenshots/widget.png) |

> Place all your screenshots inside the `docs/screenshots` folder.

---

## Demo

Watch the full demo on YouTube: [AudioMind Demo](https://youtube.com/your-demo-link-here)

---

## Setup Instructions

### iOS App

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/AudioMind.git
   cd AudioMind
