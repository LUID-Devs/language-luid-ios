//
//  AudioPlayer.swift
//  LanguageLuid
//
//  Audio player for TTS and exercise audio playback
//  Supports local and remote URLs, playback rate control, and seeking
//

import Foundation
import AVFoundation
import Combine
import os.log

/// Playback state
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(String)

    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.playing, .playing),
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

/// Audio playback errors
enum AudioPlaybackError: Error, LocalizedError {
    case invalidURL
    case loadFailed(String)
    case playbackFailed(String)
    case noActivePlayback
    case downloadFailed(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL."
        case .loadFailed(let reason):
            return "Failed to load audio: \(reason)"
        case .playbackFailed(let reason):
            return "Playback failed: \(reason)"
        case .noActivePlayback:
            return "No active audio playback."
        case .downloadFailed(let reason):
            return "Failed to download audio: \(reason)"
        case .invalidData:
            return "Invalid audio data."
        }
    }
}

/// Audio player for TTS and exercise audio
@MainActor
final class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayer()

    // MARK: - Published Properties

    @Published private(set) var state: PlaybackState = .idle
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var playbackRate: Float = 1.0
    @Published private(set) var error: Error?

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var completionHandler: (() -> Void)?
    private let audioManager = AudioManager.shared
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "AudioPlayer")

    // URL session for downloading remote audio
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    // MARK: - Initialization

    private override init() {
        super.init()
        os_log("AudioPlayer initialized", log: logger, type: .info)
    }

    deinit {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - Public Methods

    /// Play audio from URL (local or remote)
    func play(url: URL, completion: (() -> Void)? = nil) async throws {
        os_log("Playing audio from URL: %{public}@", log: logger, type: .info, url.absoluteString)

        state = .loading
        completionHandler = completion

        do {
            // Configure audio session for playback and recording
            // Use playAndRecord mode to avoid conflicts with speech recorder
            try await audioManager.configureForPlaybackAndRecording()

            // Handle remote vs local URLs
            let audioData: Data
            if url.isFileURL {
                // Local file
                audioData = try Data(contentsOf: url)
            } else {
                // Remote file - download
                audioData = try await downloadAudio(from: url)
            }

            // Play the audio data
            try await playAudioData(audioData)

        } catch let playbackError as AudioPlaybackError {
            os_log("Playback error: %{public}@", log: logger, type: .error, playbackError.localizedDescription)
            state = .error(playbackError.localizedDescription)
            error = playbackError
            throw playbackError
        } catch {
            os_log("Unexpected playback error: %{public}@", log: logger, type: .error, error.localizedDescription)
            let playbackError = AudioPlaybackError.playbackFailed(error.localizedDescription)
            state = .error(error.localizedDescription)
            self.error = playbackError
            throw playbackError
        }
    }

    /// Play audio from Data
    func play(data: Data, completion: (() -> Void)? = nil) async throws {
        os_log("Playing audio from data (%{public}d bytes)", log: logger, type: .info, data.count)

        guard !data.isEmpty else {
            os_log("Audio data is empty", log: logger, type: .error)
            throw AudioPlaybackError.invalidData
        }

        state = .loading
        completionHandler = completion

        do {
            // Configure audio session for playback and recording
            // Use playAndRecord mode to avoid conflicts with speech recorder
            try await audioManager.configureForPlaybackAndRecording()

            // Play the audio data
            try await playAudioData(data)

        } catch let playbackError as AudioPlaybackError {
            os_log("Playback error: %{public}@", log: logger, type: .error, playbackError.localizedDescription)
            state = .error(playbackError.localizedDescription)
            error = playbackError
            throw playbackError
        } catch {
            os_log("Unexpected playback error: %{public}@", log: logger, type: .error, error.localizedDescription)
            let playbackError = AudioPlaybackError.playbackFailed(error.localizedDescription)
            state = .error(error.localizedDescription)
            self.error = playbackError
            throw playbackError
        }
    }

    /// Pause playback
    func pause() {
        os_log("Pausing playback", log: logger, type: .info)

        guard state == .playing else {
            os_log("Cannot pause - not playing", log: logger, type: .error)
            return
        }

        audioPlayer?.pause()
        state = .paused
        isPlaying = false

        stopPlaybackTimer()

        os_log("Playback paused at %.2f seconds", log: logger, type: .info, currentTime)
    }

    /// Resume playback
    func resume() {
        os_log("Resuming playback", log: logger, type: .info)

        guard state == .paused else {
            os_log("Cannot resume - not paused", log: logger, type: .error)
            return
        }

        audioPlayer?.play()
        state = .playing
        isPlaying = true

        startPlaybackTimer()

        os_log("Playback resumed", log: logger, type: .info)
    }

    /// Stop playback
    func stop() {
        os_log("Stopping playback", log: logger, type: .info)

        guard state == .playing || state == .paused else {
            os_log("No active playback to stop", log: logger, type: .error)
            return
        }

        audioPlayer?.stop()
        audioPlayer?.currentTime = 0

        state = .stopped
        isPlaying = false
        currentTime = 0

        stopPlaybackTimer()

        Task {
            try? await audioManager.deactivateSession()
        }

        os_log("Playback stopped", log: logger, type: .info)
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) {
        os_log("Seeking to %.2f seconds", log: logger, type: .info, time)

        guard let player = audioPlayer else {
            os_log("No active player to seek", log: logger, type: .error)
            return
        }

        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime

        os_log("Seeked to %.2f seconds", log: logger, type: .info, clampedTime)
    }

    /// Set playback rate (0.5x to 2.0x)
    func setPlaybackRate(_ rate: Float) {
        os_log("Setting playback rate to %.2fx", log: logger, type: .info, rate)

        let clampedRate = max(0.5, min(2.0, rate))

        audioPlayer?.enableRate = true
        audioPlayer?.rate = clampedRate
        playbackRate = clampedRate

        os_log("Playback rate set to %.2fx", log: logger, type: .info, clampedRate)
    }

    /// Reset to idle state
    func reset() {
        os_log("Resetting player", log: logger, type: .info)

        audioPlayer?.stop()
        audioPlayer = nil

        state = .idle
        isPlaying = false
        currentTime = 0
        duration = 0
        playbackRate = 1.0
        error = nil
        completionHandler = nil

        stopPlaybackTimer()
    }

    // MARK: - Private Methods

    private func playAudioData(_ data: Data) async throws {
        do {
            // Create audio player
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Get duration
            duration = audioPlayer?.duration ?? 0
            currentTime = 0

            // Apply playback rate if set
            if playbackRate != 1.0 {
                audioPlayer?.enableRate = true
                audioPlayer?.rate = playbackRate
            }

            // Start playing
            guard audioPlayer?.play() == true else {
                throw AudioPlaybackError.playbackFailed("Failed to start AVAudioPlayer")
            }

            state = .playing
            isPlaying = true
            error = nil

            startPlaybackTimer()

            os_log("Playback started successfully. Duration: %.2f seconds",
                   log: logger, type: .info, duration)

        } catch {
            os_log("Failed to create audio player: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            throw AudioPlaybackError.playbackFailed(error.localizedDescription)
        }
    }

    private func downloadAudio(from url: URL) async throws -> Data {
        os_log("Downloading audio from: %{public}@", log: logger, type: .info, url.absoluteString)

        do {
            let (data, response) = try await urlSession.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw AudioPlaybackError.downloadFailed("HTTP status code: \(statusCode)")
            }

            os_log("Audio downloaded successfully (%{public}d bytes)",
                   log: logger, type: .info, data.count)

            return data

        } catch {
            os_log("Failed to download audio: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            throw AudioPlaybackError.downloadFailed(error.localizedDescription)
        }
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackTime()
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func updatePlaybackTime() {
        guard let player = audioPlayer, state == .playing else {
            return
        }

        currentTime = player.currentTime
    }

    private func handlePlaybackCompletion(successfully: Bool) {
        os_log("Playback completed (success: %{public}@)", log: logger, type: .info, successfully ? "yes" : "no")

        state = .stopped
        isPlaying = false
        currentTime = 0

        stopPlaybackTimer()

        if successfully {
            completionHandler?()
        }

        completionHandler = nil

        Task {
            try? await audioManager.deactivateSession()
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            handlePlaybackCompletion(successfully: flag)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            let errorMessage = error?.localizedDescription ?? "Unknown decode error"
            os_log("Audio decode error: %{public}@", log: logger, type: .error, errorMessage)

            state = .error(errorMessage)
            self.error = AudioPlaybackError.playbackFailed(errorMessage)
            isPlaying = false

            stopPlaybackTimer()
        }
    }
}
