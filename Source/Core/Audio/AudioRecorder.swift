//
//  AudioRecorder.swift
//  LanguageLuid
//
//  Audio recorder for speech exercises using AVFoundation
//  Records in AAC/M4A format with real-time audio level monitoring
//

import Foundation
import AVFoundation
import Combine
import os.log

/// Recording state
enum RecordingState: Equatable {
    case idle
    case recording
    case paused
    case stopped
    case error(String)

    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.recording, .recording),
             (.paused, .paused),
             (.stopped, .stopped):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Audio recording errors
enum AudioRecordingError: Error, LocalizedError {
    case permissionDenied
    case recordingFailed(String)
    case noActiveRecording
    case fileNotFound
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .noActiveRecording:
            return "No active recording to stop or pause."
        case .fileNotFound:
            return "Recording file not found."
        case .invalidState(let reason):
            return "Invalid recording state: \(reason)"
        }
    }
}

/// Audio recorder for speech exercises
@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    static let shared = AudioRecorder()

    // MARK: - Published Properties

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var recordingTime: TimeInterval = 0
    @Published private(set) var audioLevel: Float = 0.0 // -160.0 to 0.0 dB
    @Published private(set) var recordedFileURL: URL?
    @Published private(set) var error: Error?

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private let audioManager = AudioManager.shared
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "AudioRecorder")

    // Recording settings for AAC format
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC), // AAC format
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1, // Mono for speech
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128000 // 128 kbps
    ]

    // MARK: - Initialization

    private override init() {
        super.init()
        os_log("AudioRecorder initialized", log: logger, type: .info)
    }

    deinit {
        levelTimer?.invalidate()
        levelTimer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Public Methods

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        os_log("Requesting microphone permission", log: logger, type: .info)
        return await audioManager.requestMicrophonePermission()
    }

    /// Start recording audio
    func startRecording() async throws {
        os_log("Starting audio recording", log: logger, type: .info)

        // Check permission
        guard await requestMicrophonePermission() else {
            os_log("Microphone permission denied", log: logger, type: .error)
            state = .error("Microphone permission denied")
            error = AudioRecordingError.permissionDenied
            throw AudioRecordingError.permissionDenied
        }

        // Check current state
        guard state == .idle || state == .stopped else {
            let errorMsg = "Cannot start recording in current state: \(state)"
            os_log("%{public}@", log: logger, type: .error, errorMsg)
            throw AudioRecordingError.invalidState(errorMsg)
        }

        do {
            // Configure audio session
            try await audioManager.configureForRecording()

            // Create recording file URL
            let fileURL = try createRecordingFileURL()
            recordedFileURL = fileURL

            // Create and configure recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            // Start recording
            guard audioRecorder?.record() == true else {
                throw AudioRecordingError.recordingFailed("Failed to start AVAudioRecorder")
            }

            // Update state
            state = .recording
            isRecording = true
            recordingTime = 0
            error = nil

            // Start timers
            startRecordingTimer()
            startLevelMonitoring()

            os_log("Recording started successfully at: %{public}@",
                   log: logger, type: .info, fileURL.path)

        } catch let recError as AudioRecordingError {
            os_log("Recording error: %{public}@", log: logger, type: .error, recError.localizedDescription)
            state = .error(recError.localizedDescription)
            error = recError
            throw recError
        } catch {
            os_log("Unexpected recording error: %{public}@", log: logger, type: .error, error.localizedDescription)
            let recError = AudioRecordingError.recordingFailed(error.localizedDescription)
            state = .error(error.localizedDescription)
            self.error = recError
            throw recError
        }
    }

    /// Pause recording
    func pauseRecording() {
        os_log("Pausing recording", log: logger, type: .info)

        guard state == .recording else {
            os_log("Cannot pause - not recording", log: logger, type: .error)
            return
        }

        audioRecorder?.pause()
        state = .paused
        isRecording = false

        stopRecordingTimer()
        stopLevelMonitoring()

        os_log("Recording paused at %.2f seconds", log: logger, type: .info, recordingTime)
    }

    /// Resume recording
    func resumeRecording() {
        os_log("Resuming recording", log: logger, type: .info)

        guard state == .paused else {
            os_log("Cannot resume - not paused", log: logger, type: .error)
            return
        }

        audioRecorder?.record()
        state = .recording
        isRecording = true

        startRecordingTimer()
        startLevelMonitoring()

        os_log("Recording resumed", log: logger, type: .info)
    }

    /// Stop recording and return file URL
    @discardableResult
    func stopRecording() async throws -> URL {
        os_log("Stopping recording", log: logger, type: .info)

        guard state == .recording || state == .paused else {
            os_log("No active recording to stop", log: logger, type: .error)
            throw AudioRecordingError.noActiveRecording
        }

        // Stop recorder
        audioRecorder?.stop()

        // Stop timers
        stopRecordingTimer()
        stopLevelMonitoring()

        // Update state
        state = .stopped
        isRecording = false
        audioLevel = 0.0

        guard let fileURL = recordedFileURL else {
            os_log("Recording file URL not found", log: logger, type: .error)
            throw AudioRecordingError.fileNotFound
        }

        // Verify file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            os_log("Recording file does not exist at path: %{public}@",
                   log: logger, type: .error, fileURL.path)
            throw AudioRecordingError.fileNotFound
        }

        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let fileSize = attributes[.size] as? Int64 {
            os_log("Recording stopped successfully. Duration: %.2f seconds, Size: %{public}d bytes",
                   log: logger, type: .info, recordingTime, fileSize)
        }

        // Deactivate audio session
        try? await audioManager.deactivateSession()

        return fileURL
    }

    /// Cancel recording without saving
    func cancelRecording() {
        os_log("Cancelling recording", log: logger, type: .info)

        audioRecorder?.stop()
        audioRecorder?.deleteRecording()

        stopRecordingTimer()
        stopLevelMonitoring()

        // Clean up
        if let fileURL = recordedFileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Reset state
        state = .idle
        isRecording = false
        recordingTime = 0
        audioLevel = 0.0
        recordedFileURL = nil
        error = nil

        Task {
            try? await audioManager.deactivateSession()
        }

        os_log("Recording cancelled", log: logger, type: .info)
    }

    /// Delete a recording file
    func deleteRecording(url: URL) throws {
        os_log("Deleting recording at: %{public}@", log: logger, type: .info, url.path)

        guard FileManager.default.fileExists(atPath: url.path) else {
            os_log("File not found at path: %{public}@", log: logger, type: .error, url.path)
            throw AudioRecordingError.fileNotFound
        }

        try FileManager.default.removeItem(at: url)

        if recordedFileURL == url {
            recordedFileURL = nil
        }

        os_log("Recording deleted successfully", log: logger, type: .info)
    }

    /// Reset to idle state
    func reset() {
        os_log("Resetting recorder", log: logger, type: .info)

        audioRecorder = nil
        state = .idle
        isRecording = false
        recordingTime = 0
        audioLevel = 0.0
        recordedFileURL = nil
        error = nil

        stopRecordingTimer()
        stopLevelMonitoring()
    }

    // MARK: - Private Methods

    private func createRecordingFileURL() throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let recordingsURL = documentsURL.appendingPathComponent("Recordings", isDirectory: true)

        // Create recordings directory if needed
        if !fileManager.fileExists(atPath: recordingsURL.path) {
            try fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
            os_log("Created recordings directory at: %{public}@",
                   log: logger, type: .info, recordingsURL.path)
        }

        // Generate unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        let filename = "recording_\(timestamp)_\(uuid).m4a"

        return recordingsURL.appendingPathComponent(filename)
    }

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.state == .recording {
                    self.recordingTime = self.audioRecorder?.currentTime ?? 0
                }
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAudioLevel()
            }
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.0
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0.0
            return
        }

        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)

        // Convert to normalized level (0.0 to 1.0)
        // averagePower ranges from -160 dB (silence) to 0 dB (max)
        let normalizedLevel = max(0.0, min(1.0, (averagePower + 160.0) / 160.0))

        audioLevel = normalizedLevel
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                os_log("Recording finished successfully", log: logger, type: .info)
            } else {
                os_log("Recording finished with error", log: logger, type: .error)
                state = .error("Recording failed to complete")
                error = AudioRecordingError.recordingFailed("Recording did not complete successfully")
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            let errorMessage = error?.localizedDescription ?? "Unknown encoding error"
            os_log("Recording encode error: %{public}@", log: logger, type: .error, errorMessage)

            state = .error(errorMessage)
            self.error = AudioRecordingError.recordingFailed(errorMessage)
            isRecording = false

            stopRecordingTimer()
            stopLevelMonitoring()
        }
    }
}
