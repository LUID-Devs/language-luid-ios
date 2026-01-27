//
//  AudioPlayerControl.swift
//  LanguageLuid
//
//  Audio player control with TTS integration and speed controls
//  Displays play/pause button, progress bar, and speed selector
//

import SwiftUI

struct AudioPlayerControl: View {
    // MARK: - Properties

    /// Text to speak
    let text: String

    /// Language code (e.g., "es-ES", "fr-FR")
    let languageCode: String

    /// Optional voice name
    let voiceName: String?

    /// Show speed controls
    let showSpeedControl: Bool

    /// Compact mode (smaller UI)
    let isCompact: Bool

    /// Callback when playback completes
    let onComplete: (() -> Void)?

    // MARK: - State

    @StateObject private var audioPlayer = AudioPlayer.shared
    @State private var ttsService = TTSService.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var isLoading: Bool = false
    @State private var audioData: Data?
    @State private var currentSpeed: Float = 1.0
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    // Available speeds
    private let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5]

    // MARK: - Initialization

    init(
        text: String,
        languageCode: String,
        voiceName: String? = nil,
        showSpeedControl: Bool = true,
        isCompact: Bool = false,
        onComplete: (() -> Void)? = nil
    ) {
        self.text = text
        self.languageCode = languageCode
        self.voiceName = voiceName
        self.showSpeedControl = showSpeedControl
        self.isCompact = isCompact
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            // Player controls
            HStack(spacing: isCompact ? 12 : 16) {
                // Play/Pause button
                playPauseButton

                if !isCompact && audioPlayer.state == .playing || audioPlayer.state == .paused {
                    // Progress information
                    VStack(alignment: .leading, spacing: 4) {
                        // Progress bar
                        progressBar

                        // Time display
                        HStack {
                            Text(formatTime(audioPlayer.currentTime))
                                .font(.caption2)
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                            Spacer()

                            Text(formatTime(audioPlayer.duration))
                                .font(.caption2)
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                }

                // Speed control
                if showSpeedControl && !isLoading {
                    speedControlButton
                }
            }

            // Error message
            if let error = errorMessage, showError {
                errorView(error)
            }
        }
        .padding(isCompact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                .fill(LLColors.card.color(for: colorScheme))
        )
    }

    // MARK: - Play/Pause Button

    private var playPauseButton: some View {
        Button(action: togglePlayback) {
            ZStack {
                Circle()
                    .fill(playButtonColor)
                    .frame(width: isCompact ? 40 : 48, height: isCompact ? 40 : 48)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(
                                tint: LLColors.primaryForeground.color(for: colorScheme)
                            )
                        )
                        .scaleEffect(isCompact ? 0.8 : 1.0)
                } else {
                    Image(systemName: playButtonIcon)
                        .font(.system(size: isCompact ? 18 : 22))
                        .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(LLColors.muted.color(for: colorScheme).opacity(0.2))
                    .frame(height: 4)

                // Progress
                if audioPlayer.duration > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LLColors.primary.color(for: colorScheme))
                        .frame(width: geometry.size.width * CGFloat(audioPlayer.currentTime / audioPlayer.duration), height: 4)
                }
            }
        }
        .frame(height: 4)
    }

    // MARK: - Speed Control

    private var speedControlButton: some View {
        Menu {
            ForEach(speeds, id: \.self) { speed in
                Button(action: {
                    setSpeed(speed)
                }) {
                    HStack {
                        Text(speedLabel(speed))
                        if speed == currentSpeed {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.caption)
                Text(speedLabel(currentSpeed))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(LLColors.primary.color(for: colorScheme))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(LLColors.primary.color(for: colorScheme).opacity(0.1))
            )
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(LLColors.destructive.color(for: colorScheme))

            Text(message)
                .font(.caption2)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Spacer()

            Button("Dismiss") {
                showError = false
                errorMessage = nil
            }
            .font(.caption2)
            .foregroundColor(LLColors.primary.color(for: colorScheme))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LLColors.destructive.color(for: colorScheme).opacity(0.1))
        )
    }

    // MARK: - Actions

    private func togglePlayback() {
        Task {
            do {
                if audioPlayer.state == .playing {
                    // Pause
                    audioPlayer.pause()
                } else if audioPlayer.state == .paused {
                    // Resume
                    audioPlayer.resume()
                } else {
                    // Start new playback
                    await startPlayback()
                }
            }
        }
    }

    private func startPlayback() async {
        // Load audio if needed
        if audioData == nil {
            isLoading = true
            showError = false
            errorMessage = nil

            do {
                audioData = try await ttsService.synthesize(
                    text: text,
                    languageCode: languageCode,
                    voiceName: voiceName,
                    speed: currentSpeed
                )
                isLoading = false
            } catch {
                isLoading = false
                let errorDetails = error.localizedDescription
                errorMessage = "TTS Error: \(errorDetails). Check network connection and backend status."
                showError = true
                return
            }
        }

        // Play audio
        guard let data = audioData else { return }

        do {
            try await audioPlayer.play(data: data) {
                // Completion callback
                onComplete?()
            }
        } catch {
            errorMessage = "Playback error: \(error.localizedDescription)"
            showError = true
        }
    }

    private func setSpeed(_ speed: Float) {
        currentSpeed = speed
        audioPlayer.setPlaybackRate(speed)

        // Clear cached audio to force re-synthesis at new speed
        if audioPlayer.state != .playing {
            audioData = nil
        }
    }

    // MARK: - Helpers

    private var playButtonColor: Color {
        if isLoading {
            return LLColors.muted.color(for: colorScheme)
        } else if audioPlayer.state == .playing {
            return LLColors.primary.color(for: colorScheme)
        } else {
            return LLColors.primary.color(for: colorScheme)
        }
    }

    private var playButtonIcon: String {
        switch audioPlayer.state {
        case .playing:
            return "pause.fill"
        case .paused:
            return "play.fill"
        default:
            return "play.fill"
        }
    }

    private func speedLabel(_ speed: Float) -> String {
        if speed == 1.0 {
            return "1x"
        } else {
            return String(format: "%.2gx", speed)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Standard Player") {
    VStack(spacing: 20) {
        AudioPlayerControl(
            text: "Hola, ¿cómo estás?",
            languageCode: "es-ES",
            showSpeedControl: true
        )

        AudioPlayerControl(
            text: "Bonjour, comment allez-vous?",
            languageCode: "fr-FR",
            showSpeedControl: true
        )
    }
    .padding()
}

#Preview("Compact Player") {
    VStack(spacing: 12) {
        AudioPlayerControl(
            text: "Hello, how are you?",
            languageCode: "en-US",
            isCompact: true
        )

        AudioPlayerControl(
            text: "Guten Tag",
            languageCode: "de-DE",
            isCompact: true
        )
    }
    .padding()
}

#Preview("Without Speed Control") {
    AudioPlayerControl(
        text: "Ciao, come stai?",
        languageCode: "it-IT",
        showSpeedControl: false
    )
    .padding()
}
