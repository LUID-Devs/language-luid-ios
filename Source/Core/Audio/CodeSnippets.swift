//
//  CodeSnippets.swift
//  LanguageLuid
//
//  Common code snippets for audio integration
//  Copy and paste these into your views and ViewModels
//

import SwiftUI
import AVFoundation

// MARK: - Snippet 1: Basic Recording View

/*
struct BasicRecordingView: View {
    @StateObject private var recorder = AudioRecorder.shared

    var body: some View {
        VStack(spacing: 20) {
            // Recording indicator
            if recorder.isRecording {
                Text("Recording: \(formatTime(recorder.recordingTime))")
                    .font(.title)

                // Audio level bar
                ProgressView(value: recorder.audioLevel)
                    .tint(.red)
            }

            // Record/Stop button
            Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                Task {
                    if recorder.isRecording {
                        let url = try await recorder.stopRecording()
                        print("Recorded to: \(url)")
                    } else {
                        try await recorder.startRecording()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .task {
            // Request permission on appear
            let granted = await recorder.requestMicrophonePermission()
            if !granted {
                print("Microphone permission denied")
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
*/

// MARK: - Snippet 2: Exercise ViewModel with Recording

/*
@MainActor
class ExerciseViewModel: ObservableObject {
    private let recorder = AudioRecorder.shared
    private let player = AudioPlayer.shared
    private let apiClient = APIClient.shared

    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var isSubmitting = false
    @Published var evaluationResult: EvaluationResult?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Bind recorder state to view model
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

    func stopAndSubmit(exerciseId: String) async throws {
        // Stop recording
        let fileURL = try await recorder.stopRecording()

        // Read audio data
        let audioData = try Data(contentsOf: fileURL)

        // Show loading state
        isSubmitting = true
        defer { isSubmitting = false }

        // Upload to backend
        struct Response: Codable {
            let success: Bool
            let score: Double
            let feedback: String
            let pronunciationAccuracy: Double?
        }

        let response: Response = try await apiClient.uploadAudio(
            APIEndpoint.submitExercise(exerciseId),
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/x-m4a",
            parameters: [
                "exercise_id": exerciseId,
                "language": "es"
            ]
        )

        // Clean up recording file
        try? recorder.deleteRecording(url: fileURL)

        // Store result
        evaluationResult = EvaluationResult(
            score: response.score,
            feedback: response.feedback
        )
    }

    func cancelRecording() {
        recorder.cancelRecording()
    }
}

struct EvaluationResult {
    let score: Double
    let feedback: String
}
*/

// MARK: - Snippet 3: TTS Audio Playback

/*
@MainActor
class TTSViewModel: ObservableObject {
    private let player = AudioPlayer.shared
    private let apiClient = APIClient.shared

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackSpeed: Float = 1.0

    private var cancellables = Set<AnyCancellable>()

    init() {
        player.$isPlaying
            .assign(to: &$isPlaying)

        player.$currentTime
            .assign(to: &$currentTime)

        player.$duration
            .assign(to: &$duration)

        player.$playbackRate
            .assign(to: &$playbackSpeed)
    }

    func speakText(_ text: String, language: String) async throws {
        // Get TTS audio from backend
        struct TTSResponse: Codable {
            let audioUrl: String
        }

        let response: TTSResponse = try await apiClient.post(
            APIEndpoint.synthesizeSpeech,
            parameters: [
                "text": text,
                "language": language,
                "voice": "neural"
            ]
        )

        guard let audioURL = URL(string: response.audioUrl) else {
            throw AudioPlaybackError.invalidURL
        }

        // Play TTS audio
        try await player.play(url: audioURL) {
            print("TTS playback completed")
        }
    }

    func setPlaybackSpeed(_ speed: Float) {
        player.setPlaybackRate(speed)
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.resume()
    }

    func stop() {
        player.stop()
    }
}
*/

// MARK: - Snippet 4: Complete Speech Exercise View

/*
struct SpeechExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()

    let exercise: Exercise

    var body: some View {
        VStack(spacing: 24) {
            // Exercise prompt
            Text(exercise.prompt)
                .font(.title2)
                .multilineTextAlignment(.center)

            // Audio level visualization
            if viewModel.isRecording {
                AudioLevelView(level: viewModel.audioLevel)
                    .frame(height: 60)
            }

            // Recording time
            if viewModel.isRecording {
                Text(formatTime(viewModel.recordingTime))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
            }

            // Controls
            HStack(spacing: 16) {
                if !viewModel.isRecording {
                    Button {
                        Task {
                            try await viewModel.startRecording()
                        }
                    } label: {
                        Label("Record", systemImage: "mic.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button {
                        viewModel.cancelRecording()
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task {
                            try await viewModel.stopAndSubmit(exerciseId: exercise.id)
                        }
                    } label: {
                        Label("Submit", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }

            // Evaluation result
            if let result = viewModel.evaluationResult {
                VStack(spacing: 12) {
                    Text("Score: \(Int(result.score * 100))%")
                        .font(.title)
                        .foregroundColor(scoreColor(result.score))

                    Text(result.feedback)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle("Speech Exercise")
        .overlay {
            if viewModel.isSubmitting {
                ProgressView("Evaluating...")
                    .padding()
                    .background(Color.systemBackground)
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
}

struct AudioLevelView: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))

                // Level indicator
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
    }
}
*/

// MARK: - Snippet 5: Listen and Repeat Exercise

/*
struct ListenRepeatView: View {
    @StateObject private var recorder = AudioRecorder.shared
    @StateObject private var player = AudioPlayer.shared

    let promptAudioURL: URL
    let exerciseId: String

    @State private var hasPlayedPrompt = false

    var body: some View {
        VStack(spacing: 24) {
            // Listen phase
            VStack(spacing: 16) {
                Text("Listen carefully")
                    .font(.headline)

                Button {
                    Task {
                        try await player.play(url: promptAudioURL)
                        hasPlayedPrompt = true
                    }
                } label: {
                    Label("Play Prompt", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(player.isPlaying)

                if player.isPlaying {
                    ProgressView()
                }
            }

            Divider()

            // Repeat phase
            VStack(spacing: 16) {
                Text("Now you try")
                    .font(.headline)

                Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                    Task {
                        if recorder.isRecording {
                            let url = try await recorder.stopRecording()
                            await submitRecording(url)
                        } else {
                            try await recorder.startRecording()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(player.isPlaying || !hasPlayedPrompt)

                if recorder.isRecording {
                    Text(formatTime(recorder.recordingTime))
                        .font(.title)

                    ProgressView(value: recorder.audioLevel)
                        .tint(.red)
                }
            }
        }
        .padding()
    }

    private func submitRecording(_ url: URL) async {
        // Submit logic here
        print("Submitting recording: \(url)")
    }

    private func formatTime(_ time: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(time) / 60, Int(time) % 60)
    }
}
*/

// MARK: - Snippet 6: Playback Speed Control

/*
struct PlaybackSpeedControl: View {
    @StateObject private var player = AudioPlayer.shared

    var body: some View {
        VStack(spacing: 12) {
            Text("Playback Speed")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                    Button("\(String(format: "%.2f", speed))x") {
                        player.setPlaybackRate(Float(speed))
                    }
                    .buttonStyle(.bordered)
                    .tint(player.playbackRate == Float(speed) ? .blue : .gray)
                }
            }

            Text("Current: \(String(format: "%.2f", player.playbackRate))x")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
*/

// MARK: - Snippet 7: Audio Upload Helper

/*
extension APIClient {
    func uploadSpeechExercise(
        exerciseId: String,
        audioURL: URL,
        language: String
    ) async throws -> ExerciseEvaluationResponse {
        // Read audio file
        let audioData = try Data(contentsOf: audioURL)

        // Upload to backend
        let response: ExerciseEvaluationResponse = try await uploadAudio(
            APIEndpoint.submitExercise(exerciseId),
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/x-m4a",
            parameters: [
                "exercise_id": exerciseId,
                "language": language,
                "exercise_type": "pronunciation"
            ]
        )

        return response
    }
}

struct ExerciseEvaluationResponse: Codable {
    let success: Bool
    let exerciseId: String
    let score: Double
    let feedback: String
    let pronunciationAccuracy: Double?
    let fluencyScore: Double?
    let grammarScore: Double?
}
*/

// MARK: - Snippet 8: Permission Check View

/*
struct MicrophonePermissionView: View {
    @State private var permissionGranted = false
    @State private var isChecking = true

    var body: some View {
        VStack(spacing: 20) {
            if isChecking {
                ProgressView("Checking microphone permission...")
            } else if permissionGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Microphone access granted")
                    .font(.headline)
            } else {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                Text("Microphone access required")
                    .font(.headline)

                Text("Please enable microphone access in Settings to use speech exercises.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .task {
            permissionGranted = await AudioRecorder.shared.requestMicrophonePermission()
            isChecking = false
        }
    }
}
*/

// MARK: - Snippet 9: Waveform Visualization

/*
struct WaveformView: View {
    let level: Float
    let bars: Int = 20

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<bars, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4)
                    .frame(height: barHeight(for: index))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
        .frame(height: 60)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let normalizedIndex = CGFloat(index) / CGFloat(bars)
        let height = level * (1.0 - abs(normalizedIndex - 0.5) * 2)
        return CGFloat(height) * 60
    }

    private func barColor(for index: Int) -> Color {
        let normalizedIndex = CGFloat(index) / CGFloat(bars)
        if normalizedIndex < 0.5 {
            return .green
        } else if normalizedIndex < 0.75 {
            return .yellow
        } else {
            return .red
        }
    }
}
*/

// MARK: - Snippet 10: Complete Audio Service

/*
@MainActor
class AudioService: ObservableObject {
    private let recorder = AudioRecorder.shared
    private let player = AudioPlayer.shared
    private let apiClient = APIClient.shared

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var playbackTime: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        recorder.$isRecording.assign(to: &$isRecording)
        recorder.$recordingTime.assign(to: &$recordingTime)
        recorder.$audioLevel.assign(to: &$audioLevel)
        player.$isPlaying.assign(to: &$isPlaying)
        player.$currentTime.assign(to: &$playbackTime)
    }

    // Recording
    func startRecording() async throws {
        try await recorder.startRecording()
    }

    func stopRecording() async throws -> URL {
        return try await recorder.stopRecording()
    }

    func cancelRecording() {
        recorder.cancelRecording()
    }

    // Playback
    func play(url: URL, completion: (() -> Void)? = nil) async throws {
        try await player.play(url: url, completion: completion)
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.resume()
    }

    func setSpeed(_ speed: Float) {
        player.setPlaybackRate(speed)
    }

    // Upload
    func uploadAndEvaluate(
        exerciseId: String,
        audioURL: URL,
        language: String
    ) async throws -> ExerciseEvaluationResponse {
        let audioData = try Data(contentsOf: audioURL)

        let response: ExerciseEvaluationResponse = try await apiClient.uploadAudio(
            APIEndpoint.submitExercise(exerciseId),
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/x-m4a",
            parameters: [
                "exercise_id": exerciseId,
                "language": language
            ]
        )

        // Clean up
        try? recorder.deleteRecording(url: audioURL)

        return response
    }
}
*/
