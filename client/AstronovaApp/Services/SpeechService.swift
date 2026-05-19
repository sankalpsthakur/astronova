import AVFoundation
import Combine
import UIKit
import os.log

/// Centralized text-to-speech service for Astronova.
///
/// Per `launch-artifacts/feedback-design-wave-2026-05-18.md` §0.3 + §9.1:
/// - Voice reading is opt-in via Settings → Self → More Options → "Voice reading"
/// - VoiceOver passthrough: if VoiceOver is running we skip our TTS so the
///   screen reader can drive narration (§10.7).
/// - Audio session is `.playback`/`.spokenAudio` with `.duckOthers` +
///   `.mixWithOthers` so Spotify/music ducks during speech and resumes after
///   `setActive(false, options: .notifyOthersOnDeactivation)` (§10.1).
/// - All failures are swallowed and logged via os.Logger — never crash.
@MainActor
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    /// UserDefaults key used by the in-app "Voice reading" toggle.
    /// MUST match the @AppStorage key in MoreOptionsSheet.
    static let voiceReadingEnabledKey = "astronova.voice_reading_enabled"

    @Published private(set) var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "com.astronova.app", category: "tts")
    private var didConfigureSession = false

    #if DEBUG
    /// Wave 3b QA counter — increments on every successful call into `speak(_:)`
    /// that reaches the synthesizer (i.e. not gated out by VoiceOver or the
    /// voice-reading toggle). UI tests read it via `UserDefaults` to verify
    /// J5 (button increments) and J6 (toggle gates) without scraping the
    /// audio session. NEVER read this in production paths.
    static let debugSpeakCallCounterKey = "astronova.qa.speech_speak_counter"
    #endif

    override private init() {
        super.init()
        synthesizer.delegate = self
        // Default the setting ON the first time (matches @AppStorage default in MoreOptionsSheet).
        if UserDefaults.standard.object(forKey: Self.voiceReadingEnabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.voiceReadingEnabledKey)
        }
    }

    /// Whether voice reading is enabled in app Settings.
    /// Falls back to `true` if the key is unset (first-run default per §0.3).
    static var isVoiceReadingEnabled: Bool {
        if UserDefaults.standard.object(forKey: voiceReadingEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: voiceReadingEnabledKey)
    }

    /// Speak `text` once. No-op if already speaking (call `stop()` first to interrupt).
    /// Respects the in-app TTS opt-out setting and VoiceOver passthrough.
    ///
    /// - Parameter force: bypass the in-app toggle (e.g., for critical
    ///   accessibility passthrough). VoiceOver is still respected.
    func speak(_ text: String,
               language: String? = nil,
               rate: Float = AVSpeechUtteranceDefaultSpeechRate,
               pitch: Float = 1.0,
               force: Bool = false) {
        guard !text.isEmpty else { return }

        // VoiceOver passthrough (§10.7): if VoiceOver is on, let the screen
        // reader drive narration. We skip even when `force` is true because
        // doubling up screen reader + custom TTS is the bug we're avoiding.
        if UIAccessibility.isVoiceOverRunning {
            logger.debug("speak() skipped — VoiceOver running")
            return
        }

        if !force && !Self.isVoiceReadingEnabled {
            logger.debug("speak() skipped — voice reading disabled")
            return
        }

        guard !synthesizer.isSpeaking else {
            logger.debug("speak() ignored — already speaking")
            return
        }

        configureSessionIfNeeded()

        let utterance = AVSpeechUtterance(string: text)
        let locale = language ?? Locale.current.identifier
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = 1.0

        synthesizer.speak(utterance)

        #if DEBUG
        // Increment the QA counter only AFTER we've decided to speak —
        // i.e. it captures the "speech actually happened" event.
        let current = UserDefaults.standard.integer(forKey: Self.debugSpeakCallCounterKey)
        UserDefaults.standard.set(current + 1, forKey: Self.debugSpeakCallCounterKey)
        #endif
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        deactivateSession()
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio,
                                    options: [.duckOthers, .mixWithOthers])
            try session.setActive(true, options: [])
            didConfigureSession = true
        } catch {
            logger.error("AVAudioSession setup failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: [.notifyOthersOnDeactivation])
            didConfigureSession = false
        } catch {
            logger.error("AVAudioSession deactivation failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.deactivateSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.deactivateSession()
        }
    }
}
