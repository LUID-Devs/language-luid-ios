# Audio Infrastructure

Comprehensive audio recording and playback system for Language Luid iOS app.

## Overview

This audio infrastructure provides production-ready components for speech-first language learning:

- **AudioManager**: Centralized AVAudioSession manager
- **AudioRecorder**: High-quality audio recording with real-time monitoring
- **AudioPlayer**: Audio playback for TTS and exercise audio
- **AudioExample**: Example SwiftUI view demonstrating usage

## Features

### AudioRecorder
- ✅ AAC/M4A format recording (iOS standard)
- ✅ Real-time audio level monitoring for waveforms
- ✅ Record, pause, resume, stop, cancel
- ✅ Automatic file management in Documents directory
- ✅ Reactive state with Combine publishers
- ✅ Comprehensive error handling
- ✅ Async/await API

### AudioPlayer
- ✅ Play from URL (local or remote)
- ✅ Play from Data
- ✅ Playback rate control (0.5x - 2.0x)
- ✅ Seek support
- ✅ Progress tracking
- ✅ Completion callbacks
- ✅ Automatic audio session management

### AudioManager
- ✅ Centralized AVAudioSession configuration
- ✅ Handle interruptions (calls, Siri, etc.)
- ✅ Route change handling (headphones connect/disconnect)
- ✅ Microphone permission management
- ✅ Background audio support
- ✅ Reactive state publishing

## Quick Start

### Recording Audio

```swift
import SwiftUI

struct RecordingView: View {
    @StateObject private var recorder = AudioRecorder.shared

    var body: some View {
        VStack {
            Text(formatTime(recorder.recordingTime))

            // Audio level visualization
            ProgressView(value: recorder.audioLevel)

            if recorder.state == .idle {
                Button("Record") {
                    Task {
                        try await recorder.startRecording()
                    }
                }
            } else if recorder.isRecording {
                Button("Stop") {
                    Task {
                        let url = try await recorder.stopRecording()
                        print("Recorded to: \(url)")
                    }
                }
            }
        }
        .task {
            await recorder.requestMicrophonePermission()
        }
    }
}
```

### Playing Audio

```swift
import SwiftUI

struct PlaybackView: View {
    @StateObject private var player = AudioPlayer.shared

    func playAudio(url: URL) {
        Task {
            try await player.play(url: url) {
                print("Playback completed!")
            }
        }
    }

    var body: some View {
        VStack {
            Text("\(Int(player.currentTime))s / \(Int(player.duration))s")

            if player.isPlaying {
                Button("Pause") { player.pause() }
            } else {
                Button("Play") { player.resume() }
            }

            // Playback rate
            Picker("Speed", selection: .constant(1.0)) {
                Text("0.5x").tag(0.5)
                Text("1.0x").tag(1.0)
                Text("1.5x").tag(1.5)
            }
            .onChange(of: player.playbackRate) { rate in
                player.setPlaybackRate(rate)
            }
        }
    }
}
```

## Integration with Backend

### Uploading Recorded Audio

```swift
import Foundation

class SpeechExerciseViewModel {
    private let recorder = AudioRecorder.shared
    private let apiClient = APIClient.shared

    func submitSpeechExercise(exerciseId: String) async throws {
        // Stop recording
        let fileURL = try await recorder.stopRecording()

        // Read audio data
        let audioData = try Data(contentsOf: fileURL)

        // Upload to backend
        struct Response: Codable {
            let success: Bool
            let score: Double
            let feedback: String
        }

        let response: Response = try await apiClient.uploadAudio(
            "/api/exercises/\(exerciseId)/submit",
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/x-m4a",  // or "audio/aac", "audio/mp4"
            parameters: [
                "exercise_id": exerciseId,
                "language": "es"
            ]
        )

        // Clean up
        try? recorder.deleteRecording(url: fileURL)

        // Handle response
        print("Score: \(response.score)")
    }
}
```

### Playing TTS Audio

```swift
class TTSService {
    private let player = AudioPlayer.shared
    private let apiClient = APIClient.shared

    func speakText(_ text: String, language: String) async throws {
        // Get TTS audio URL from backend
        struct TTSResponse: Codable {
            let audioUrl: String
        }

        let response: TTSResponse = try await apiClient.post(
            "/api/tts",
            parameters: [
                "text": text,
                "language": language,
                "voice": "neural"
            ]
        )

        guard let url = URL(string: response.audioUrl) else {
            throw AudioPlaybackError.invalidURL
        }

        // Play audio (handles download automatically)
        try await player.play(url: url) {
            print("TTS playback completed")
        }
    }
}
```

## Audio Formats

### Recording Format
- **Container**: M4A (MPEG-4 Audio)
- **Codec**: AAC (Advanced Audio Coding)
- **Sample Rate**: 44.1 kHz
- **Channels**: Mono (1 channel)
- **Bit Rate**: 128 kbps
- **Quality**: High

### Supported Playback Formats
- AAC (.aac, .m4a)
- MP3 (.mp3)
- WAV (.wav)
- AIFF (.aiff)
- CAF (.caf)

### MIME Types Accepted by Backend
- `audio/aac`
- `audio/mp4`
- `audio/x-m4a`
- `audio/m4a`

## File Management

### Recording Location
Recordings are saved in:
```
<App Documents>/Recordings/recording_<timestamp>_<uuid>.m4a
```

Example path:
```
/var/mobile/Containers/Data/Application/<UUID>/Documents/Recordings/recording_1234567890_abc123.m4a
```

### Cleanup Best Practices

```swift
// Clean up after upload
try? recorder.deleteRecording(url: recordedURL)

// Clean up old recordings (optional)
func cleanupOldRecordings() throws {
    let fileManager = FileManager.default
    let documentsURL = try fileManager.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    )
    let recordingsURL = documentsURL.appendingPathComponent("Recordings")

    let files = try fileManager.contentsOfDirectory(
        at: recordingsURL,
        includingPropertiesForKeys: [.creationDateKey]
    )

    let oldFiles = files.filter { url in
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let date = attrs[.creationDate] as? Date else {
            return false
        }
        return Date().timeIntervalSince(date) > 86400 // 24 hours
    }

    for file in oldFiles {
        try? fileManager.removeItem(at: file)
    }
}
```

## State Management

### Recording States
```swift
enum RecordingState {
    case idle        // Ready to record
    case recording   // Currently recording
    case paused      // Recording paused
    case stopped     // Recording stopped, file available
    case error(String) // Error occurred
}
```

### Playback States
```swift
enum PlaybackState {
    case idle        // No audio loaded
    case loading     // Loading audio file
    case playing     // Currently playing
    case paused      // Playback paused
    case stopped     // Playback stopped
    case error(String) // Error occurred
}
```

## Published Properties

### AudioRecorder
```swift
@Published var state: RecordingState
@Published var isRecording: Bool
@Published var recordingTime: TimeInterval
@Published var audioLevel: Float  // 0.0 to 1.0 (normalized)
@Published var recordedFileURL: URL?
@Published var error: Error?
```

### AudioPlayer
```swift
@Published var state: PlaybackState
@Published var isPlaying: Bool
@Published var currentTime: TimeInterval
@Published var duration: TimeInterval
@Published var playbackRate: Float  // 0.5 to 2.0
@Published var error: Error?
```

### AudioManager
```swift
@Published var currentMode: AudioSessionMode
@Published var isSessionActive: Bool
@Published var currentRoute: String
@Published var isHeadphonesConnected: Bool
```

## Error Handling

### Recording Errors
```swift
do {
    try await recorder.startRecording()
} catch AudioRecordingError.permissionDenied {
    // Show settings alert
} catch AudioRecordingError.recordingFailed(let reason) {
    // Show error to user
} catch {
    // Handle unexpected errors
}
```

### Playback Errors
```swift
do {
    try await player.play(url: audioURL)
} catch AudioPlaybackError.downloadFailed(let reason) {
    // Network error
} catch AudioPlaybackError.playbackFailed(let reason) {
    // Playback error
} catch {
    // Handle unexpected errors
}
```

## Advanced Features

### Real-Time Audio Level Monitoring

```swift
// In your view
ProgressView(value: recorder.audioLevel)
    .accentColor(levelColor(recorder.audioLevel))

func levelColor(_ level: Float) -> Color {
    switch level {
    case 0..<0.3: return .green
    case 0.3..<0.7: return .yellow
    default: return .red
    }
}
```

### Custom Playback Rate for Learning

```swift
// Slow down for beginners
player.setPlaybackRate(0.75)  // 75% speed

// Normal speed
player.setPlaybackRate(1.0)   // 100% speed

// Fast for practice
player.setPlaybackRate(1.5)   // 150% speed
```

### Seeking in Audio

```swift
// Seek to 5 seconds
player.seek(to: 5.0)

// Seek to middle
player.seek(to: player.duration / 2)

// Seek on progress bar tap
GeometryReader { geometry in
    Rectangle()
        .onTapGesture { location in
            let ratio = location.x / geometry.size.width
            let seekTime = player.duration * ratio
            player.seek(to: seekTime)
        }
}
```

## Permissions

### Info.plist Required Keys

Add these to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your pronunciation for speech exercises.</string>
```

### Requesting Permission

```swift
// Check permission status
if AudioManager.shared.hasMicrophonePermission {
    // Permission already granted
} else {
    // Request permission
    let granted = await AudioRecorder.shared.requestMicrophonePermission()
    if !granted {
        // Show settings alert
    }
}
```

## Testing

### Simulator Notes
- Recording works in iOS Simulator (uses host Mac's microphone)
- Playback works in Simulator
- Audio levels may behave differently than on device

### Device Testing
- Test with AirPods/Bluetooth headphones
- Test during phone call interruption
- Test with low storage
- Test with airplane mode (for offline playback)
- Test background audio

### Unit Testing Example

```swift
import XCTest

class AudioRecorderTests: XCTestCase {
    @MainActor
    func testRecordingFlow() async throws {
        let recorder = AudioRecorder.shared

        // Request permission
        let granted = await recorder.requestMicrophonePermission()
        XCTAssertTrue(granted)

        // Start recording
        try await recorder.startRecording()
        XCTAssertEqual(recorder.state, .recording)
        XCTAssertTrue(recorder.isRecording)

        // Wait 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)
        XCTAssertGreaterThan(recorder.recordingTime, 1.9)

        // Stop recording
        let url = try await recorder.stopRecording()
        XCTAssertEqual(recorder.state, .stopped)
        XCTAssertFalse(recorder.isRecording)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Clean up
        try recorder.deleteRecording(url: url)
    }
}
```

## Performance Considerations

### Memory
- Audio data is loaded into memory during playback
- For large files, consider streaming (future enhancement)
- Clean up recordings after upload to save space

### Battery
- Recording is battery-intensive
- Disable level monitoring when not needed
- Stop audio session when not in use

### Network
- Remote audio is downloaded before playback
- Consider caching frequently used audio
- Show loading state during download

## Troubleshooting

### Common Issues

**Recording not starting**
- Check microphone permission
- Verify audio session configuration
- Check for conflicting audio (other apps)

**No sound during playback**
- Check device volume
- Verify audio file format
- Check audio route (speaker vs headphones)

**Audio level always zero**
- Ensure metering is enabled
- Check microphone is not muted
- Verify audio session category

**File not found after recording**
- Check disk space
- Verify Documents directory permissions
- Look for iOS storage optimization

## Future Enhancements

- [ ] Audio streaming for large files
- [ ] Audio caching layer
- [ ] Waveform visualization
- [ ] Audio trimming/editing
- [ ] Multiple format support
- [ ] Noise cancellation
- [ ] Audio effects (reverb, echo)
- [ ] Background recording
- [ ] Speech-to-text integration

## Architecture

```
AudioManager (Singleton)
    ├── Manages AVAudioSession
    ├── Handles interruptions
    └── Routes audio I/O

AudioRecorder (Singleton)
    ├── Uses AVAudioRecorder
    ├── Depends on AudioManager
    └── Publishes state via Combine

AudioPlayer (Singleton)
    ├── Uses AVAudioPlayer
    ├── Depends on AudioManager
    └── Publishes state via Combine
```

## Dependencies

- **AVFoundation**: Core audio framework
- **Combine**: Reactive state management
- **OSLog**: Comprehensive logging
- **Foundation**: File management

**No external dependencies required!**

## License

Part of Language Luid iOS app.

---

For questions or issues, see the main project documentation.
