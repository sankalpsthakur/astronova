import Foundation
import SwiftUI

// MARK: - Oracle Message

struct OracleMessage: Identifiable, Equatable, Codable {
    let id: String
    let text: String
    let isUser: Bool
    let type: MessageType
    let timestamp: Date
    var isExpanded: Bool = false

    enum MessageType: String, Codable {
        case welcome
        case question
        case insight
        case signal  // Today's proactive insight

        var icon: String {
            switch self {
            case .welcome: return "sparkles"
            case .question: return "bubble.right"
            case .insight: return "sun.max"
            case .signal: return "waveform.path.ecg"
            }
        }
    }

    static func == (lhs: OracleMessage, rhs: OracleMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Oracle Session Memory

/// Persists the last `maxMessages` exchanged with Shastriji across app launches.
/// Keyed per user id (or "anon" when unauthenticated). Stored as JSON in UserDefaults —
/// good enough for short rolling history; for cross-device sync, move to iCloud KVStore.
struct OracleSessionMemory {
    static let maxMessages = 5
    private static let prefix = "oracle.memory.v1."
    private static let defaults = UserDefaults.standard

    static func key(for userId: String?) -> String {
        let suffix = (userId?.isEmpty == false ? userId! : "anon")
        return "\(prefix)\(suffix)"
    }

    static func load(userId: String?) -> [OracleMessage] {
        guard let data = defaults.data(forKey: key(for: userId)) else { return [] }
        return (try? JSONDecoder().decode([OracleMessage].self, from: data)) ?? []
    }

    static func save(_ messages: [OracleMessage], userId: String?) {
        // Drop transient welcome messages so they regenerate fresh each session.
        let persisted = messages.filter { $0.type != .welcome }.suffix(maxMessages)
        if let data = try? JSONEncoder().encode(Array(persisted)) {
            defaults.set(data, forKey: key(for: userId))
        }
    }

    static func clear(userId: String?) {
        defaults.removeObject(forKey: key(for: userId))
    }
}

// MARK: - Oracle View Model

@MainActor
final class OracleViewModel: ObservableObject {

    // MARK: - Published State

    @Published var messages: [OracleMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedDepth: OracleDepth = .quick
    @Published var showingPaywall: Bool = false
    @Published var showingCreditPacks: Bool = false

    /// Shastriji's opening ceremony — true while the "is preparing your reading…" overlay
    /// shows on a fresh session, briefly hushing the screen before the first message.
    @Published var isPreparingCeremony: Bool = false

    // MARK: - Dependencies

    let quotaManager: OracleQuotaManager
    private let apiServices = APIServices.shared
    /// Memory is keyed per local-device user. Resolved from UserDefaults; falls back to "anon".
    private var userId: String? {
        UserDefaults.standard.string(forKey: "userId")
            ?? UserDefaults.standard.string(forKey: "user_id")
    }

    // MARK: - Contextual Prompts

    let contextualPrompts: [String] = [
        L10n.Oracle.Prompts.energyToday,
        L10n.Oracle.Prompts.highestPath,
        L10n.Oracle.Prompts.influences,
        L10n.Oracle.Prompts.focusNow
    ]

    // MARK: - Initialization

    init(quotaManager: OracleQuotaManager? = nil) {
        self.quotaManager = quotaManager ?? .shared
        beginSession()
    }

    /// Begin a fresh Shastriji session:
    /// 1. Show the brief opening ceremony.
    /// 2. Hydrate persisted history (last 5 messages).
    /// 3. Add a context-aware welcome line from Shastriji.
    private func beginSession() {
        let restored = OracleSessionMemory.load(userId: userId)
        messages = restored

        isPreparingCeremony = true
        // 2s ceremony — long enough to feel intentional, short enough not to annoy.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self else { return }
            self.isPreparingCeremony = false
            self.addWelcomeMessage(continuing: !restored.isEmpty)
        }
    }

    // MARK: - Public Methods

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Check quota
        guard quotaManager.canAfford(depth: selectedDepth) else {
            errorMessage = L10n.Oracle.dailyLimitReached
            return
        }

        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        Analytics.shared.track(.oracleChatSent, properties: [
            "depth": selectedDepth.rawValue,
            "message_length": "\(userText.count)"
        ])

        // Add user message
        let userMessage = OracleMessage(
            id: UUID().uuidString,
            text: userText,
            isUser: true,
            type: .question,
            timestamp: Date()
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            messages.append(userMessage)
        }
        persistMemory()

        // Clear input and start loading
        inputText = ""
        errorMessage = nil
        isLoading = true

        // Send to API
        Task {
            await fetchResponse(for: userText)
        }
    }

    func selectPrompt(_ prompt: String) {
        inputText = prompt
    }

    func dismissError() {
        errorMessage = nil
    }

    func toggleMessageExpansion(_ message: OracleMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].isExpanded.toggle()
        }
    }

    // MARK: - Private Methods

    private func addWelcomeMessage(continuing: Bool = false) {
        // Shastriji's voice — different opener for a returning user vs a fresh seat.
        let firstTimeOpeners = [
            "Hmm. Sit with me a moment — let me look at the sky for you.",
            "Come, settle in. The cosmos has been waiting for this question.",
            "Ah. There is something to say here. Ask, and I will read what I see."
        ]
        let returningOpeners = [
            "You return. The thread is still warm — what shall we read tonight?",
            "Welcome back. The sky has moved since we last spoke. What weighs on you?",
            "Hmm. Where we left off, the Moon was elsewhere. Ask again — gently."
        ]
        let pool = continuing ? returningOpeners : firstTimeOpeners
        let text = pool.randomElement() ?? L10n.Oracle.welcomeMessage

        let welcome = OracleMessage(
            id: "welcome",
            text: text,
            isUser: false,
            type: .welcome,
            timestamp: Date()
        )
        messages.append(welcome)
    }

    /// Persist the last 5 messages so the next session can continue the thread.
    private func persistMemory() {
        OracleSessionMemory.save(messages, userId: userId)
    }

    private func fetchResponse(for question: String) async {
        do {
            // Build context (simplified for now)
            let context = "depth=\(selectedDepth.rawValue.lowercased())"

            let response = try await apiServices.sendChatMessage(question, context: context)

            isLoading = false

            let aiMessage = OracleMessage(
                id: UUID().uuidString,
                text: response.reply,
                isUser: false,
                type: .insight,
                timestamp: Date()
            )

            Analytics.shared.track(.oracleChatReceived, properties: [
                "response_length": "\(response.reply.count)",
                "depth": selectedDepth.rawValue
            ])

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                messages.append(aiMessage)
            }
            persistMemory()

            // Record usage
            quotaManager.recordUsage(depth: selectedDepth)

        } catch {
            isLoading = false
            if let networkError = error as? NetworkError {
                switch networkError {
                case .authenticationFailed, .tokenExpired:
                    errorMessage = L10n.Oracle.signInRequired
                case .offline:
                    errorMessage = L10n.Errors.noInternet
                case .timeout:
                    errorMessage = L10n.Errors.timeout
                case .serverError(let code, _):
                    errorMessage = L10n.Errors.serverError(code)
                default:
                    errorMessage = L10n.Errors.connectionInterrupted
                }
            } else {
                errorMessage = L10n.Errors.connectionInterrupted
            }
        }
    }
}
