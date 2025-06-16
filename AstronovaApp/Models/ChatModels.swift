import Foundation

// MARK: - Chat Models

/// Chat message request
struct ChatRequest: Codable {
    let message: String
    let context: ChatContext?
}

/// Chat context for personalized responses
struct ChatContext: Codable {
    let userChart: ChartResponse?
    let currentTransits: [String: PlanetaryPosition]?
    let preferences: [String: String]?
}

/// Chat response
struct ChatResponse: Codable {
    let reply: String
    let messageId: String
    let suggestedFollowUps: [String]
}

/// Chat message for history
struct ChatMessage: Codable {
    let id: String
    let message: String
    let response: String
    let timestamp: String
    let userId: String?
}