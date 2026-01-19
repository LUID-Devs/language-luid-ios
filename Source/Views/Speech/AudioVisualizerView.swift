//
//  AudioVisualizerView.swift
//  LanguageLuid
//
//  Real-time audio waveform visualizer for speech recording
//  Displays animated bars based on microphone audio levels
//

import SwiftUI

/// Audio waveform visualizer with animated bars
struct AudioVisualizerView: View {
    // MARK: - Properties

    /// Audio level (0.0 to 1.0)
    let audioLevel: Float

    /// Number of bars to display
    let barCount: Int

    /// Bar spacing
    let spacing: CGFloat

    /// Minimum bar height
    let minHeight: CGFloat

    /// Maximum bar height
    let maxHeight: CGFloat

    /// Bar color
    let color: Color

    /// Whether recording is active
    let isRecording: Bool

    // MARK: - State

    @State private var barHeights: [CGFloat] = []
    @State private var animationPhase: Double = 0

    // MARK: - Initialization

    init(
        audioLevel: Float,
        isRecording: Bool = false,
        barCount: Int = 40,
        spacing: CGFloat = 2,
        minHeight: CGFloat = 4,
        maxHeight: CGFloat = 100,
        color: Color = Color(uiColor: UIColor.systemBlue)
    ) {
        self.audioLevel = audioLevel
        self.isRecording = isRecording
        self.barCount = barCount
        self.spacing = spacing
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.color = color
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: barWidth, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: audioLevel)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxHeight)
        .onAppear {
            initializeBarHeights()
        }
        .onChange(of: audioLevel) { oldValue, newValue in
            updateBarHeights()
        }
        .onChange(of: isRecording) { oldValue, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    // MARK: - Computed Properties

    private var barWidth: CGFloat {
        // Calculate bar width based on available space
        let totalSpacing = spacing * CGFloat(barCount - 1)
        let availableWidth = UIScreen.main.bounds.width - (spacing * 4) // Account for padding
        return max(2, (availableWidth - totalSpacing) / CGFloat(barCount))
    }

    // MARK: - Private Methods

    private func initializeBarHeights() {
        barHeights = (0..<barCount).map { _ in minHeight }
    }

    private func updateBarHeights() {
        guard isRecording else {
            // Reset to min height when not recording
            barHeights = (0..<barCount).map { _ in minHeight }
            return
        }

        // Update bar heights based on audio level
        let normalizedLevel = CGFloat(audioLevel)
        let amplitude = minHeight + (maxHeight - minHeight) * normalizedLevel

        // Create wave effect with some randomness
        barHeights = (0..<barCount).map { index in
            let position = CGFloat(index) / CGFloat(barCount)
            let wave = sin(position * CGFloat.pi * 4 + CGFloat(animationPhase))
            let randomFactor = CGFloat.random(in: 0.7...1.3)
            let height = amplitude * abs(wave) * randomFactor
            return max(minHeight, min(maxHeight, height))
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard index < barHeights.count else { return minHeight }
        return barHeights[index]
    }

    private func barColor(for index: Int) -> Color {
        // Create gradient effect from center
        let position = abs(CGFloat(index) - CGFloat(barCount) / 2.0) / (CGFloat(barCount) / 2.0)
        let opacity = 1.0 - (position * 0.5)
        return color.opacity(opacity)
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 0.05).repeatForever(autoreverses: false)) {
            animationPhase += 0.1
        }
    }

    private func stopAnimation() {
        animationPhase = 0
        initializeBarHeights()
    }
}

// MARK: - Preview

#Preview("Idle") {
    VStack(spacing: 32) {
        Text("Idle State")
            .font(.headline)

        AudioVisualizerView(
            audioLevel: 0.0,
            isRecording: false
        )
        .padding()
    }
}

#Preview("Recording - Low Level") {
    VStack(spacing: 32) {
        Text("Recording - Low Level")
            .font(.headline)

        AudioVisualizerView(
            audioLevel: 0.2,
            isRecording: true
        )
        .padding()
    }
}

#Preview("Recording - Medium Level") {
    VStack(spacing: 32) {
        Text("Recording - Medium Level")
            .font(.headline)

        AudioVisualizerView(
            audioLevel: 0.5,
            isRecording: true,
            color: .green
        )
        .padding()
    }
}

#Preview("Recording - High Level") {
    VStack(spacing: 32) {
        Text("Recording - High Level")
            .font(.headline)

        AudioVisualizerView(
            audioLevel: 0.9,
            isRecording: true,
            color: .red
        )
        .padding()
    }
}
