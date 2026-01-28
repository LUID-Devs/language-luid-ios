//
//  AudioVisualizerView.swift
//  LanguageLuid
//
//  Modern circular audio waveform visualizer for speech recording
//  Inspired by iOS native audio interfaces (Siri, Voice Memos)
//  Features smooth pulsing rings that expand based on audio amplitude
//

import SwiftUI
import os.log

/// Modern circular audio waveform visualizer with pulsing rings
/// Provides clear visual feedback during pronunciation exercises
struct AudioVisualizerView: View {
    // MARK: - Properties

    /// Audio level (0.0 to 1.0)
    let audioLevel: Float

    /// Whether recording is active
    let isRecording: Bool

    /// Primary color for the visualizer
    let color: Color

    /// Number of concentric rings to display
    private let ringCount: Int = 3

    /// Base size of the center circle
    private let baseCenterSize: CGFloat = 60

    /// Maximum scale factor for rings when at full volume
    private let maxScale: CGFloat = 2.2

    /// Minimum audio level threshold to trigger animation (0.15 = speaking threshold)
    /// Normal speech is typically 0.1-0.8, so 0.15 filters out room noise
    private let animationThreshold: Float = 0.15

    // MARK: - State

    @State private var animationPhase: Double = 0
    @State private var isAnimating: Bool = false
    @State private var ringScales: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var ringOpacities: [Double] = [0.6, 0.4, 0.2]

    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "AudioVisualizer")

    // MARK: - Initialization

    init(
        audioLevel: Float,
        isRecording: Bool = false,
        color: Color = Color(uiColor: UIColor.systemBlue)
    ) {
        self.audioLevel = audioLevel
        self.isRecording = isRecording
        self.color = color
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Outer rings (animated when speaking)
            ForEach(0..<ringCount, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(ringOpacities[index]), lineWidth: 2)
                    .frame(width: baseCenterSize, height: baseCenterSize)
                    .scaleEffect(ringScales[index])
                    .blur(radius: CGFloat(index) * 0.5)
            }

            // Center solid circle (always visible)
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.8),
                            color.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: baseCenterSize, height: baseCenterSize)
                .scaleEffect(centerScale)
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

            // Inner pulse circle (visible when speaking)
            if isSpeaking {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: baseCenterSize * 0.5, height: baseCenterSize * 0.5)
                    .scaleEffect(pulseScale)
                    .blur(radius: 2)
            }
        }
        .frame(width: containerSize, height: containerSize)
        .onChange(of: audioLevel) { oldValue, newValue in
            updateVisualization(newValue)
        }
        .onChange(of: isRecording) { oldValue, newValue in
            if !newValue {
                resetVisualization()
            }
        }
        .onAppear {
            resetVisualization()
        }
    }

    // MARK: - Computed Properties

    /// Whether the user is currently speaking (above threshold)
    private var isSpeaking: Bool {
        isRecording && audioLevel > animationThreshold
    }

    /// Container size to accommodate maximum ring expansion
    private var containerSize: CGFloat {
        baseCenterSize * maxScale * 1.2
    }

    /// Scale factor for the center circle based on audio level
    private var centerScale: CGFloat {
        guard isSpeaking else { return 1.0 }

        // Subtle pulse of center circle (1.0 to 1.15)
        let normalizedLevel = CGFloat(min(1.0, audioLevel))
        return 1.0 + (normalizedLevel * 0.15)
    }

    /// Scale factor for the inner pulse effect
    private var pulseScale: CGFloat {
        guard isSpeaking else { return 1.0 }

        // Pulse between 1.0 and 2.0 based on audio level and animation phase
        let normalizedLevel = CGFloat(min(1.0, audioLevel))
        let phaseFactor = sin(animationPhase * 2) * 0.3 + 0.7
        return 1.0 + (normalizedLevel * phaseFactor)
    }

    // MARK: - Private Methods

    /// Update the visualization based on current audio level
    private func updateVisualization(_ level: Float) {
        guard isRecording else {
            resetVisualization()
            return
        }

        let speaking = level > animationThreshold

        if speaking {
            // Start or continue animation
            if !isAnimating {
                startAnimation()
            }

            // Update ring scales based on audio level
            let normalizedLevel = CGFloat(min(1.0, level))

            withAnimation(.easeOut(duration: 0.1)) {
                // Rings expand outward based on audio level
                // Each ring has a different scale and timing offset
                ringScales[0] = 1.0 + (normalizedLevel * (maxScale - 1.0) * 0.4)
                ringScales[1] = 1.0 + (normalizedLevel * (maxScale - 1.0) * 0.7)
                ringScales[2] = 1.0 + (normalizedLevel * (maxScale - 1.0) * 1.0)

                // Opacity decreases as rings expand
                ringOpacities[0] = 0.6 * (1.0 - normalizedLevel * 0.3)
                ringOpacities[1] = 0.4 * (1.0 - normalizedLevel * 0.4)
                ringOpacities[2] = 0.2 * (1.0 - normalizedLevel * 0.5)
            }
        } else {
            // User stopped speaking - smoothly return to idle state
            stopAnimation()
        }
    }

    /// Start the continuous animation loop
    private func startAnimation() {
        guard !isAnimating else { return }

        isAnimating = true

        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }

    /// Stop the animation and return to idle state
    private func stopAnimation() {
        isAnimating = false

        withAnimation(.easeOut(duration: 0.3)) {
            animationPhase = 0
            ringScales = [1.0, 1.0, 1.0]
            ringOpacities = [0.6, 0.4, 0.2]
        }
    }

    /// Reset visualization to initial state
    private func resetVisualization() {
        animationPhase = 0
        isAnimating = false

        withAnimation(.easeOut(duration: 0.2)) {
            ringScales = [1.0, 1.0, 1.0]
            ringOpacities = [0.6, 0.4, 0.2]
        }
    }
}

// MARK: - Preview Helpers

/// Preview wrapper for testing different audio states
private struct AudioVisualizerPreviewWrapper: View {
    @State private var audioLevel: Float
    @State private var isRecording: Bool
    let color: Color
    let label: String

    init(audioLevel: Float, isRecording: Bool, color: Color = .blue, label: String) {
        self._audioLevel = State(initialValue: audioLevel)
        self._isRecording = State(initialValue: isRecording)
        self.color = color
        self.label = label
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(label)
                .font(.headline)

            AudioVisualizerView(
                audioLevel: audioLevel,
                isRecording: isRecording,
                color: color
            )

            if isRecording {
                VStack(spacing: 8) {
                    Text("Audio Level: \(String(format: "%.2f", audioLevel))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: Binding(
                        get: { Double(audioLevel) },
                        set: { audioLevel = Float($0) }
                    ), in: 0...1)
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Idle State") {
    VStack(spacing: 40) {
        AudioVisualizerPreviewWrapper(
            audioLevel: 0.0,
            isRecording: false,
            color: .blue,
            label: "Idle - Not Recording"
        )

        AudioVisualizerPreviewWrapper(
            audioLevel: 0.05,
            isRecording: true,
            color: .blue,
            label: "Recording - Silent (below threshold)"
        )
    }
}

#Preview("Speaking - Low Volume") {
    AudioVisualizerPreviewWrapper(
        audioLevel: 0.2,
        isRecording: true,
        color: .green,
        label: "Speaking - Low Volume"
    )
}

#Preview("Speaking - Medium Volume") {
    AudioVisualizerPreviewWrapper(
        audioLevel: 0.5,
        isRecording: true,
        color: .blue,
        label: "Speaking - Medium Volume"
    )
}

#Preview("Speaking - High Volume") {
    AudioVisualizerPreviewWrapper(
        audioLevel: 0.9,
        isRecording: true,
        color: .orange,
        label: "Speaking - High Volume"
    )
}

#Preview("Interactive Test") {
    AudioVisualizerPreviewWrapper(
        audioLevel: 0.5,
        isRecording: true,
        color: Color(uiColor: UIColor.systemBlue),
        label: "Interactive - Adjust the slider"
    )
}

#Preview("Dark Mode") {
    VStack(spacing: 40) {
        AudioVisualizerPreviewWrapper(
            audioLevel: 0.0,
            isRecording: false,
            color: .blue,
            label: "Idle - Dark Mode"
        )

        AudioVisualizerPreviewWrapper(
            audioLevel: 0.6,
            isRecording: true,
            color: .blue,
            label: "Speaking - Dark Mode"
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Multiple Colors") {
    VStack(spacing: 32) {
        HStack(spacing: 32) {
            VStack {
                Text("Blue")
                    .font(.caption)
                AudioVisualizerView(audioLevel: 0.6, isRecording: true, color: .blue)
            }

            VStack {
                Text("Green")
                    .font(.caption)
                AudioVisualizerView(audioLevel: 0.6, isRecording: true, color: .green)
            }
        }

        HStack(spacing: 32) {
            VStack {
                Text("Orange")
                    .font(.caption)
                AudioVisualizerView(audioLevel: 0.6, isRecording: true, color: .orange)
            }

            VStack {
                Text("Purple")
                    .font(.caption)
                AudioVisualizerView(audioLevel: 0.6, isRecording: true, color: .purple)
            }
        }
    }
    .padding()
}
