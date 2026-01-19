//
//  AudioManager.swift
//  LanguageLuid
//
//  Centralized audio session manager for recording and playback
//  Handles interruptions, route changes, and session configuration
//

import Foundation
import AVFoundation
import os.log

/// Audio session errors
enum AudioSessionError: Error, LocalizedError {
    case sessionConfigurationFailed(Error)
    case activationFailed(Error)
    case deactivationFailed(Error)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .sessionConfigurationFailed(let error):
            return "Failed to configure audio session: \(error.localizedDescription)"
        case .activationFailed(let error):
            return "Failed to activate audio session: \(error.localizedDescription)"
        case .deactivationFailed(let error):
            return "Failed to deactivate audio session: \(error.localizedDescription)"
        case .permissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        }
    }
}

/// Audio session mode for different use cases
enum AudioSessionMode {
    case idle
    case recording
    case playback
    case playbackAndRecording
}

/// Centralized audio session manager
@MainActor
final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published Properties

    @Published private(set) var currentMode: AudioSessionMode = .idle
    @Published private(set) var isSessionActive: Bool = false
    @Published private(set) var currentRoute: String = ""
    @Published private(set) var isHeadphonesConnected: Bool = false

    // MARK: - Private Properties

    private let audioSession = AVAudioSession.sharedInstance()
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "AudioManager")

    // MARK: - Initialization

    private override init() {
        super.init()
        setupNotifications()
        updateRouteInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Configure audio session for recording
    func configureForRecording() async throws {
        os_log("Configuring audio session for recording", log: logger, type: .info)

        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )

            // Prefer built-in microphone for recording quality
            try audioSession.setPreferredInput(audioSession.availableInputs?.first { $0.portType == .builtInMic })

            // Set sample rate for better quality
            try audioSession.setPreferredSampleRate(44100.0)

            // Set IO buffer duration for lower latency
            try audioSession.setPreferredIOBufferDuration(0.005)

            try audioSession.setActive(true)

            currentMode = .recording
            isSessionActive = true
            updateRouteInfo()

            os_log("Audio session configured for recording successfully", log: logger, type: .info)
        } catch {
            os_log("Failed to configure audio session for recording: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            throw AudioSessionError.sessionConfigurationFailed(error)
        }
    }

    /// Configure audio session for playback
    func configureForPlayback() async throws {
        os_log("Configuring audio session for playback", log: logger, type: .info)

        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )

            try audioSession.setActive(true)

            currentMode = .playback
            isSessionActive = true
            updateRouteInfo()

            os_log("Audio session configured for playback successfully", log: logger, type: .info)
        } catch {
            os_log("Failed to configure audio session for playback: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            throw AudioSessionError.sessionConfigurationFailed(error)
        }
    }

    /// Configure audio session for simultaneous playback and recording
    func configureForPlaybackAndRecording() async throws {
        os_log("Configuring audio session for playback and recording", log: logger, type: .info)

        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
            )

            try audioSession.setActive(true)

            currentMode = .playbackAndRecording
            isSessionActive = true
            updateRouteInfo()

            os_log("Audio session configured for playback and recording successfully", log: logger, type: .info)
        } catch {
            os_log("Failed to configure audio session for playback and recording: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            throw AudioSessionError.sessionConfigurationFailed(error)
        }
    }

    /// Deactivate audio session
    func deactivateSession() async throws {
        guard isSessionActive else { return }

        os_log("Deactivating audio session", log: logger, type: .info)

        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)

            currentMode = .idle
            isSessionActive = false

            os_log("Audio session deactivated successfully", log: logger, type: .info)
        } catch {
            os_log("Failed to deactivate audio session: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            throw AudioSessionError.deactivationFailed(error)
        }
    }

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        let status = audioSession.recordPermission

        switch status {
        case .granted:
            os_log("Microphone permission already granted", log: logger, type: .info)
            return true

        case .denied:
            os_log("Microphone permission denied", log: logger, type: .error)
            return false

        case .undetermined:
            os_log("Requesting microphone permission", log: logger, type: .info)

            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    Task { @MainActor in
                        os_log("Microphone permission %{public}@",
                               log: self.logger, type: .info, granted ? "granted" : "denied")
                        continuation.resume(returning: granted)
                    }
                }
            }

        @unknown default:
            os_log("Unknown microphone permission status", log: logger, type: .error)
            return false
        }
    }

    /// Check if microphone permission is granted
    var hasMicrophonePermission: Bool {
        return audioSession.recordPermission == .granted
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        Task { @MainActor in
            switch type {
            case .began:
                os_log("Audio session interrupted (began)", log: logger, type: .info)
                // Recording/playback will be automatically paused

            case .ended:
                os_log("Audio session interruption ended", log: logger, type: .info)

                // Check if we should resume
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        os_log("Should resume after interruption", log: logger, type: .info)
                        // Let AudioRecorder/AudioPlayer handle resumption
                    }
                }

            @unknown default:
                break
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        Task { @MainActor in
            updateRouteInfo()

            switch reason {
            case .newDeviceAvailable:
                os_log("New audio device available: %{public}@", log: logger, type: .info, currentRoute)

            case .oldDeviceUnavailable:
                os_log("Audio device unavailable: %{public}@", log: logger, type: .info, currentRoute)
                // Headphones were unplugged - let AudioRecorder/AudioPlayer handle this

            case .categoryChange:
                os_log("Audio category changed", log: logger, type: .info)

            case .override:
                os_log("Audio route overridden", log: logger, type: .info)

            case .wakeFromSleep:
                os_log("Audio route changed due to wake from sleep", log: logger, type: .info)

            case .noSuitableRouteForCategory:
                os_log("No suitable route for category", log: logger, type: .error)

            case .routeConfigurationChange:
                os_log("Audio route configuration changed", log: logger, type: .info)

            @unknown default:
                os_log("Unknown route change reason: %{public}d", log: logger, type: .info, reasonValue)
            }
        }
    }

    private func updateRouteInfo() {
        let currentRouteOutputs = audioSession.currentRoute.outputs
        if let output = currentRouteOutputs.first {
            currentRoute = output.portName

            // Check if headphones are connected
            isHeadphonesConnected = [
                .headphones,
                .bluetoothA2DP,
                .bluetoothHFP,
                .bluetoothLE
            ].contains(output.portType)

            os_log("Current audio route: %{public}@ (headphones: %{public}@)",
                   log: logger, type: .info, currentRoute, isHeadphonesConnected ? "yes" : "no")
        }
    }
}
