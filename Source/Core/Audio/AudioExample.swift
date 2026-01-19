//
//  AudioExample.swift
//  LanguageLuid
//
//  Example usage and test view for audio recording and playback
//  This demonstrates how to use AudioRecorder and AudioPlayer in your views
//

import SwiftUI
import AVFoundation

/// Example view demonstrating audio recording and playback
struct AudioExampleView: View {
    @StateObject private var recorder = AudioRecorder.shared
    @StateObject private var player = AudioPlayer.shared
    @State private var permissionGranted = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Recording Section
                VStack(spacing: 16) {
                    Text("Audio Recording")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Recording state indicator
                    HStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recorder.isRecording)

                        Text(stateText(recorder.state))
                            .font(.headline)
                    }

                    // Recording time
                    if recorder.isRecording || recorder.state == .paused || recorder.state == .stopped {
                        Text(formatTime(recorder.recordingTime))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                    }

                    // Audio level visualization
                    if recorder.isRecording {
                        VStack(spacing: 8) {
                            Text("Audio Level")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))

                                    // Level indicator
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.green, .yellow, .orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(recorder.audioLevel))
                                        .animation(.linear(duration: 0.05), value: recorder.audioLevel)
                                }
                            }
                            .frame(height: 24)
                        }
                        .padding(.horizontal)
                    }

                    // Recording controls
                    HStack(spacing: 16) {
                        if recorder.state == .idle || recorder.state == .stopped {
                            Button(action: startRecording) {
                                Label("Record", systemImage: "mic.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                        }

                        if recorder.state == .recording {
                            Button(action: { recorder.pauseRecording() }) {
                                Label("Pause", systemImage: "pause.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }

                            Button(action: stopRecording) {
                                Label("Stop", systemImage: "stop.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray)
                                    .cornerRadius(12)
                            }
                        }

                        if recorder.state == .paused {
                            Button(action: { recorder.resumeRecording() }) {
                                Label("Resume", systemImage: "play.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }

                            Button(action: { recorder.cancelRecording() }) {
                                Label("Cancel", systemImage: "xmark.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Play recorded audio button
                    if recorder.state == .stopped, let fileURL = recorder.recordedFileURL {
                        Button(action: { playRecording(url: fileURL) }) {
                            Label("Play Recording", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)

                Divider()

                // MARK: - Playback Section
                VStack(spacing: 16) {
                    Text("Audio Playback")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Playback state indicator
                    HStack {
                        Circle()
                            .fill(player.isPlaying ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: player.isPlaying)

                        Text(stateText(player.state))
                            .font(.headline)
                    }

                    // Playback time
                    if player.duration > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text(formatTime(player.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(formatTime(player.duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * CGFloat(player.currentTime / max(player.duration, 1)))
                                }
                            }
                            .frame(height: 8)
                            .onTapGesture { location in
                                // Seek on tap (would need geometry reader context)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Playback controls
                    HStack(spacing: 16) {
                        if player.state == .playing {
                            Button(action: { player.pause() }) {
                                Label("Pause", systemImage: "pause.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }

                        if player.state == .paused {
                            Button(action: { player.resume() }) {
                                Label("Resume", systemImage: "play.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }

                        if player.state == .playing || player.state == .paused {
                            Button(action: { player.stop() }) {
                                Label("Stop", systemImage: "stop.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Playback rate control
                    if player.state == .playing || player.state == .paused {
                        VStack(spacing: 8) {
                            Text("Playback Rate: \(String(format: "%.1fx", player.playbackRate))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Button("0.5x") { player.setPlaybackRate(0.5) }
                                Button("0.75x") { player.setPlaybackRate(0.75) }
                                Button("1.0x") { player.setPlaybackRate(1.0) }
                                Button("1.25x") { player.setPlaybackRate(1.25) }
                                Button("1.5x") { player.setPlaybackRate(1.5) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)

                // MARK: - Info Section
                VStack(spacing: 12) {
                    Text("Audio Info")
                        .font(.headline)

                    if let url = recorder.recordedFileURL {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recording Path:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            if let size = fileSize(at: url) {
                                Text("Size: \(size)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Audio Example")
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // Request permission on appear
            permissionGranted = await recorder.requestMicrophonePermission()
            if !permissionGranted {
                errorMessage = "Microphone permission is required for recording."
                showError = true
            }
        }
    }

    // MARK: - Helper Methods

    private func startRecording() {
        Task {
            do {
                try await recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stopRecording() {
        Task {
            do {
                _ = try await recorder.stopRecording()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func playRecording(url: URL) {
        Task {
            do {
                try await player.play(url: url) {
                    print("Playback completed!")
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stateText(_ state: RecordingState) -> String {
        switch state {
        case .idle: return "Idle"
        case .recording: return "Recording..."
        case .paused: return "Paused"
        case .stopped: return "Stopped"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private func stateText(_ state: PlaybackState) -> String {
        switch state {
        case .idle: return "Idle"
        case .loading: return "Loading..."
        case .playing: return "Playing..."
        case .paused: return "Paused"
        case .stopped: return "Stopped"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }

    private func fileSize(at url: URL) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AudioExampleView()
    }
}

// MARK: - Usage Examples in ViewModels

/**
 Example: Using AudioRecorder in a speech exercise ViewModel

 ```swift
 @MainActor
 class SpeechExerciseViewModel: ObservableObject {
     private let recorder = AudioRecorder.shared
     private let player = AudioPlayer.shared
     private let apiClient = APIClient.shared

     @Published var isRecording = false
     @Published var recordingTime: TimeInterval = 0
     @Published var audioLevel: Float = 0

     init() {
         // Observe recorder state
         recorder.$isRecording
             .assign(to: &$isRecording)

         recorder.$recordingTime
             .assign(to: &$recordingTime)

         recorder.$audioLevel
             .assign(to: &$audioLevel)
     }

     func startRecording() async throws {
         try await recorder.startRecording()
     }

     func stopAndSubmit() async throws {
         // Stop recording and get file URL
         let fileURL = try await recorder.stopRecording()

         // Read audio data
         let audioData = try Data(contentsOf: fileURL)

         // Upload to backend
         let response: SpeechEvaluationResponse = try await apiClient.uploadAudio(
             "/api/exercises/\(exerciseId)/submit",
             fileData: audioData,
             fileName: "recording.m4a",
             mimeType: "audio/x-m4a",
             parameters: ["exercise_id": exerciseId]
         )

         // Clean up recording file
         try? recorder.deleteRecording(url: fileURL)

         // Handle response
         handleEvaluation(response)
     }

     func playPromptAudio(url: URL) async throws {
         try await player.play(url: url) {
             print("Prompt audio finished")
         }
     }

     func setSlowPlayback() {
         player.setPlaybackRate(0.75)
     }
 }
 ```

 Example: Using AudioPlayer for TTS

 ```swift
 @MainActor
 class TTSViewModel: ObservableObject {
     private let player = AudioPlayer.shared
     private let apiClient = APIClient.shared

     @Published var isPlaying = false
     @Published var playbackRate: Float = 1.0

     func speakText(_ text: String) async throws {
         // Get TTS audio from backend
         let response: TTSResponse = try await apiClient.post(
             "/api/tts",
             parameters: ["text": text, "language": "es"]
         )

         // Play TTS audio from URL
         guard let audioURL = URL(string: response.audioUrl) else {
             throw AudioPlaybackError.invalidURL
         }

         try await player.play(url: audioURL) {
             print("TTS completed")
         }
     }

     func setSlowSpeed() {
         player.setPlaybackRate(0.75)
     }

     func setNormalSpeed() {
         player.setPlaybackRate(1.0)
     }
 }
 ```
 */
