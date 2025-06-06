import Foundation
import DataModels

/// Service for integrating with Claude API for astrology chat functionality.
public final class ClaudeAPIService: ObservableObject {
    
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let session = URLSession.shared
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Sends a message to Claude and returns the response.
    public func sendMessage(_ message: String, conversationHistory: [ChatMessage], userProfile: UserProfile?) async throws -> String {
        let request = try buildRequest(message: message, conversationHistory: conversationHistory, userProfile: userProfile)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ChatError.httpError(httpResponse.statusCode)
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        
        guard let content = claudeResponse.content.first?.text else {
            throw ChatError.noContent
        }
        
        return content
    }
    
    /// Generates suggested questions based on user profile and context.
    public func generateSuggestedQuestions(userProfile: UserProfile?) async throws -> [String] {
        let context = buildAstrologyContext(userProfile: userProfile)
        let prompt = """
        Based on this astrology profile: \(context)
        
        Generate 3 engaging astrology questions that would be relevant for this person. 
        Return them as a JSON array of strings. Only return the JSON, no other text.
        """
        
        let suggestions = try await sendMessage(prompt, conversationHistory: [], userProfile: userProfile)
        
        // Parse JSON response
        guard let data = suggestions.data(using: .utf8),
              let questions = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            // Fallback questions if parsing fails
            return [
                "What does my birth chart say about my personality?",
                "What career paths align with my astrological profile?",
                "How do planetary transits affect me this month?"
            ]
        }
        
        return questions
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(message: String, conversationHistory: [ChatMessage], userProfile: UserProfile?) throws -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let systemPrompt = buildSystemPrompt(userProfile: userProfile)
        let messages = buildMessages(from: conversationHistory, newMessage: message)
        
        let requestBody = ClaudeRequest(
            model: "claude-3-sonnet-20240229",
            maxTokens: 1000,
            system: systemPrompt,
            messages: messages
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }
    
    private func buildSystemPrompt(userProfile: UserProfile?) -> String {
        let basePrompt = """
        You are an expert astrologer and spiritual guide specializing in Vedic and Western astrology. 
        You provide insightful, compassionate, and practical astrological guidance.
        
        Guidelines:
        - Be warm, encouraging, and supportive
        - Provide specific astrological insights when possible
        - Explain astrological concepts in accessible language
        - Focus on empowerment and growth
        - Keep responses concise but meaningful
        """
        
        if let profile = userProfile {
            let profileContext = buildAstrologyContext(userProfile: profile)
            return basePrompt + "\n\nUser's Astrological Profile:\n\(profileContext)"
        }
        
        return basePrompt
    }
    
    private func buildAstrologyContext(userProfile: UserProfile?) -> String {
        guard let profile = userProfile else {
            return "No profile information available."
        }
        
        return """
        Sun Sign: \(profile.sunSign)
        Moon Sign: \(profile.moonSign)
        Rising Sign: \(profile.risingSign)
        Birth Date: \(DateFormatter.userFriendly.string(from: profile.birthDate))
        """
    }
    
    private func buildMessages(from history: [ChatMessage], newMessage: String) -> [ClaudeMessage] {
        var messages: [ClaudeMessage] = []
        
        // Add conversation history
        for message in history.suffix(10) { // Limit to last 10 messages
            if message.role == .user || message.role == .assistant {
                messages.append(ClaudeMessage(
                    role: message.role.rawValue,
                    content: [ClaudeTextContent(text: message.content)]
                ))
            }
        }
        
        // Add new user message
        messages.append(ClaudeMessage(role: "user", content: [ClaudeTextContent(text: newMessage)]))
        
        return messages
    }
}

// MARK: - Data Models

private struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

private struct ClaudeMessage: Codable {
    let role: String
    let content: [ClaudeTextContent]
}

private struct ClaudeTextContent: Codable {
    let type: String
    let text: String
    
    init(text: String) {
        self.type = "text"
        self.text = text
    }
}

private struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
    
    struct ClaudeContent: Codable {
        let text: String
    }
}

// MARK: - Error Types

public enum ChatError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case noContent
    case apiKeyMissing
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .noContent:
            return "No content in response"
        case .apiKeyMissing:
            return "API key is missing"
        case .custom(let message):
            return message
        }
    }
    
    public static func premiumRequired(_ message: String) -> ChatError {
        return .custom(message)
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let userFriendly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}