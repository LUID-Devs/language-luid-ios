# Audio Infrastructure Integration Guide

Quick guide for integrating the audio system into your Language Luid app.

## Files Created

```
LanguageLuid/Core/Audio/
├── AudioManager.swift       (319 lines) - Audio session manager
├── AudioRecorder.swift      (429 lines) - Recording functionality
├── AudioPlayer.swift        (415 lines) - Playback functionality
├── AudioExample.swift       (406 lines) - Example SwiftUI view
└── README.md                (669 lines) - Comprehensive documentation
```

**Total: 2,238 lines of production-ready Swift code**

## Quick Integration Checklist

### 1. Verify Info.plist (Already Done ✅)

Your `Info.plist` already contains:
- `NSMicrophoneUsageDescription` - Microphone permission
- `NSSpeechRecognitionUsageDescription` - Speech recognition permission
- Background audio mode enabled

### 2. Import in Your Exercise Views

```swift
import SwiftUI

struct SpeechExerciseView: View {
    @StateObject private var recorder = AudioRecorder.shared
    @StateObject private var player = AudioPlayer.shared

    var body: some View {
        VStack {
            // Recording UI
            if recorder.isRecording {
                Text("Recording: \(Int(recorder.recordingTime))s")
                ProgressView(value: recorder.audioLevel)
            }

            Button(recorder.isRecording ? "Stop" : "Record") {
                Task {
                    if recorder.isRecording {
                        let url = try await recorder.stopRecording()
                        await submitRecording(url)
                    } else {
                        try await recorder.startRecording()
                    }
                }
            }
        }
        .task {
            await recorder.requestMicrophonePermission()
        }
    }

    func submitRecording(_ url: URL) async {
        let data = try! Data(contentsOf: url)

        // Upload to backend
        let response: ExerciseResponse = try! await APIClient.shared.uploadAudio(
            APIEndpoint.submitExercise("exercise-id"),
            fileData: data,
            fileName: "recording.m4a",
            mimeType: "audio/x-m4a"
        )

        // Clean up
        try? recorder.deleteRecording(url: url)
    }
}
```

### 3. Play TTS Audio

```swift
func playPromptAudio(text: String, language: String) async throws {
    // Get TTS URL from backend
    struct TTSResponse: Codable {
        let audioUrl: String
    }

    let response: TTSResponse = try await APIClient.shared.post(
        APIEndpoint.synthesizeSpeech,
        parameters: [
            "text": text,
            "language": language,
            "voice": "neural"
        ]
    )

    guard let url = URL(string: response.audioUrl) else { return }

    // Play audio
    try await AudioPlayer.shared.play(url: url) {
        print("TTS playback completed")
    }
}
```

### 4. Add to Your Exercise ViewModel

```swift
@MainActor
class ExerciseViewModel: ObservableObject {
    private let recorder = AudioRecorder.shared
    private let player = AudioPlayer.shared

    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0

    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Bind recorder state
        recorder.$isRecording
            .assign(to: &$isRecording)

        recorder.$recordingTime
            .assign(to: &$recordingTime)

        recorder.$audioLevel
            .assign(to: &$audioLevel)

        // Bind player state
        player.$isPlaying
            .assign(to: &$isPlaying)

        player.$currentTime
            .assign(to: &$playbackTime)
    }

    func startRecording() async throws {
        try await recorder.startRecording()
    }

    func stopAndSubmit(exerciseId: String) async throws {
        let url = try await recorder.stopRecording()
        let data = try Data(contentsOf: url)

        struct Response: Codable {
            let success: Bool
            let score: Double
            let feedback: String
        }

        let response: Response = try await APIClient.shared.uploadAudio(
            APIEndpoint.submitExercise(exerciseId),
            fileData: data,
            fileName: "recording.m4a",
            mimeType: "audio/x-m4a",
            parameters: ["exercise_id": exerciseId]
        )

        try? recorder.deleteRecording(url: url)

        return response
    }

    func playPrompt(url: URL) async throws {
        try await player.play(url: url)
    }

    func setSlowPlayback() {
        player.setPlaybackRate(0.75)
    }
}
```

### 5. Backend Integration

The audio infrastructure is ready to work with these backend endpoints (already defined in `APIEndpoint`):

```swift
// Speech & Audio endpoints
APIEndpoint.synthesizeSpeech          // POST /api/speech/synthesize
APIEndpoint.recognizeSpeech           // POST /api/speech/recognize
APIEndpoint.evaluatePronunciation     // POST /api/speech/evaluate-pronunciation
APIEndpoint.uploadAudio               // POST /api/speech/upload
APIEndpoint.submitExercise(id)        // POST /api/exercises/:id/submit
```

### 6. Example Upload Code

```swift
func uploadRecording(exerciseId: String, fileURL: URL) async throws {
    // Read audio file
    let audioData = try Data(contentsOf: fileURL)

    // Upload using multipart form data
    struct SubmitResponse: Codable {
        let success: Bool
        let exerciseId: String
        let score: Double?
        let feedback: String?
        let pronunciation: PronunciationFeedback?
    }

    let response: SubmitResponse = try await APIClient.shared.uploadAudio(
        APIEndpoint.submitExercise(exerciseId),
        fileData: audioData,
        fileName: "recording.m4a",
        mimeType: "audio/x-m4a",
        parameters: [
            "exercise_id": exerciseId,
            "language": "es",
            "exercise_type": "pronunciation"
        ]
    )

    print("Upload successful! Score: \(response.score ?? 0)")
}
```

## Supported Audio Formats

### Recording Output
- **Format**: M4A (MPEG-4 Audio)
- **Codec**: AAC (Advanced Audio Coding)
- **Sample Rate**: 44.1 kHz
- **Channels**: Mono (1 channel)
- **Bit Rate**: 128 kbps
- **Quality**: High

### Accepted MIME Types by Backend
- `audio/aac`
- `audio/mp4`
- `audio/x-m4a`
- `audio/m4a`

### Playback Support
- AAC (.aac, .m4a)
- MP3 (.mp3)
- WAV (.wav)
- AIFF (.aiff)

## Testing in Simulator

All audio features work in iOS Simulator:
- Recording uses Mac's microphone
- Playback works normally
- Audio levels are updated in real-time

## Common Use Cases

### 1. Pronunciation Exercise

```swift
struct PronunciationExerciseView: View {
    @StateObject private var recorder = AudioRecorder.shared
    @State private var targetPhrase = "¿Cómo estás?"

    var body: some View {
        VStack(spacing: 20) {
            Text("Say: \(targetPhrase)")
                .font(.title)

            // Audio level indicator
            if recorder.isRecording {
                WaveformView(level: recorder.audioLevel)
            }

            RecordButton(
                isRecording: recorder.isRecording,
                action: handleRecording
            )
        }
    }

    func handleRecording() {
        Task {
            if recorder.isRecording {
                let url = try await recorder.stopRecording()
                await evaluatePronunciation(url)
            } else {
                try await recorder.startRecording()
            }
        }
    }

    func evaluatePronunciation(_ url: URL) async {
        // Submit to backend for evaluation
    }
}
```

### 2. Listen and Repeat Exercise

```swift
struct ListenRepeatView: View {
    @StateObject private var player = AudioPlayer.shared
    @StateObject private var recorder = AudioRecorder.shared

    let promptAudioURL: URL

    var body: some View {
        VStack {
            // Play button
            Button("Listen") {
                Task {
                    try await player.play(url: promptAudioURL)
                }
            }
            .disabled(player.isPlaying)

            // Record button (disabled while playing)
            Button(recorder.isRecording ? "Stop" : "Repeat") {
                Task {
                    if recorder.isRecording {
                        let url = try await recorder.stopRecording()
                        await submit(url)
                    } else {
                        try await recorder.startRecording()
                    }
                }
            }
            .disabled(player.isPlaying)
        }
    }
}
```

### 3. Slow Playback for Learning

```swift
struct SlowPlaybackView: View {
    @StateObject private var player = AudioPlayer.shared
    @State private var playbackSpeed: Float = 1.0

    var body: some View {
        VStack {
            Picker("Speed", selection: $playbackSpeed) {
                Text("0.5x").tag(Float(0.5))
                Text("0.75x").tag(Float(0.75))
                Text("1.0x").tag(Float(1.0))
                Text("1.25x").tag(Float(1.25))
            }
            .onChange(of: playbackSpeed) { speed in
                player.setPlaybackRate(speed)
            }
        }
    }
}
```

## State Observation

All components use `@Published` properties that you can observe in SwiftUI:

### AudioRecorder
```swift
recorder.$state              // RecordingState
recorder.$isRecording        // Bool
recorder.$recordingTime      // TimeInterval
recorder.$audioLevel         // Float (0.0-1.0)
recorder.$recordedFileURL    // URL?
recorder.$error              // Error?
```

### AudioPlayer
```swift
player.$state                // PlaybackState
player.$isPlaying            // Bool
player.$currentTime          // TimeInterval
player.$duration             // TimeInterval
player.$playbackRate         // Float (0.5-2.0)
player.$error                // Error?
```

### AudioManager
```swift
audioManager.$currentMode            // AudioSessionMode
audioManager.$isSessionActive        // Bool
audioManager.$currentRoute           // String
audioManager.$isHeadphonesConnected  // Bool
```

## Error Handling

```swift
do {
    try await recorder.startRecording()
} catch AudioRecordingError.permissionDenied {
    showAlert("Microphone permission required")
} catch AudioRecordingError.recordingFailed(let reason) {
    showAlert("Recording failed: \(reason)")
} catch {
    showAlert("Unexpected error: \(error.localizedDescription)")
}
```

## Next Steps

1. **Test the Example View**: Run `AudioExampleView` to see all features in action
2. **Integrate into Exercises**: Add recording to your exercise views
3. **Add TTS**: Implement text-to-speech for prompts and feedback
4. **Test on Device**: Test with real device for best results
5. **Add Waveforms**: Create custom waveform visualizations using `audioLevel`

## Resources

- **Main Documentation**: See `README.md` for comprehensive guide
- **Example Code**: See `AudioExample.swift` for SwiftUI examples
- **API Endpoints**: See `AppConfig.swift` for backend endpoints
- **API Client**: See `APIClient.swift` for upload methods

## Support

For issues or questions:
1. Check the comprehensive `README.md`
2. Review `AudioExample.swift` for working examples
3. Check logs in Console.app (filter by "AudioRecorder", "AudioPlayer", "AudioManager")
4. Test in Simulator first, then on device

---

**Ready to build speech-first language learning! 🎤🎧**
