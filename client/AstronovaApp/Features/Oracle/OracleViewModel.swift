import Foundation
import SwiftUI

// MARK: - Oracle Message

struct OracleMessage: Identifiable, Equatable {
    let id: String
    let text: String
    let isUser: Bool
    let type: MessageType
    let timestamp: Date
    var isExpanded: Bool = false

    enum MessageType {
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

    // MARK: - Dependencies

    let quotaManager: OracleQuotaManager
    private let apiServices = APIServices.shared

    // MARK: - Contextual Prompts

    let contextualPrompts: [String] = [
        "What energy surrounds me today?",
        "How can I align with my highest path?",
        "What planetary influences affect me?",
        "Where should I focus my energy now?"
    ]

    // MARK: - Initialization

    init(quotaManager: OracleQuotaManager? = nil) {
        self.quotaManager = quotaManager ?? .shared
        addWelcomeMessage()
    }

    // MARK: - Public Methods

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Check quota
        guard quotaManager.canAfford(depth: selectedDepth) else {
            errorMessage = "Daily reading complete"
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

    private func addWelcomeMessage() {
        let welcome = OracleMessage(
            id: "welcome",
            text: "The stars are aligned. What guidance do you seek?",
            isUser: false,
            type: .welcome,
            timestamp: Date()
        )
        messages.append(welcome)
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

            // Record usage
            quotaManager.recordUsage(depth: selectedDepth)

        } catch {
            isLoading = false
            if let networkError = error as? NetworkError {
                switch networkError {
                case .authenticationFailed, .tokenExpired:
                    errorMessage = "Sign in to ask the Oracle."
                case .offline:
                    errorMessage = "No internet connection. Please try again."
                case .timeout:
                    errorMessage = "Request timed out. Please try again."
                case .serverError(let code, _):
                    errorMessage = "Server error (\(code)). Please try again."
                default:
                    errorMessage = "Connection interrupted"
                }
            } else {
                errorMessage = "Connection interrupted"
            }
        }
    }
}
