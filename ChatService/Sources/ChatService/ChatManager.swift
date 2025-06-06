import Foundation
import DataModels
import AuthKit
import Combine

/// Main chat manager that orchestrates Claude API integration and chat data management.
public final class ChatManager: ObservableObject {
    
    @Published public private(set) var isProcessing = false
    @Published public private(set) var suggestedQuestions: [String] = []
    @Published public private(set) var error: ChatError?
    
    private let claudeService: ClaudeAPIService
    private let repository: ChatRepository
    private let authManager: AuthManager
    
    public init(apiKey: String, authManager: AuthManager) {
        self.claudeService = ClaudeAPIService(apiKey: apiKey)
        self.repository = ChatRepository()
        self.authManager = authManager
    }
    
    // MARK: - Public API
    
    /// Repository for accessing conversations and messages.
    public var chatRepository: ChatRepository { repository }
    
    /// Sends a message and gets Claude's response.
    @MainActor
    public func sendMessage(_ content: String, in conversationID: String) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        error = nil
        
        do {
            // Add user message
            let userMessage = ChatMessage(
                content: content,
                role: .user,
                conversationID: conversationID
            )
            try await repository.addMessage(userMessage)
            
            // Get user profile for context
            let userProfile = try? await fetchUserProfile()
            
            // Send to Claude
            let response = try await claudeService.sendMessage(
                content,
                conversationHistory: repository.currentMessages,
                userProfile: userProfile
            )
            
            // Add Claude's response
            let assistantMessage = ChatMessage(
                content: response,
                role: .assistant,
                conversationID: conversationID
            )
            try await repository.addMessage(assistantMessage)
            
        } catch {
            self.error = error as? ChatError ?? .invalidResponse
        }
        
        isProcessing = false
    }
    
    /// Creates a new conversation with an initial message.
    @MainActor
    public func startNewConversation(with message: String) async -> ChatConversation? {
        guard !isProcessing else { return nil }
        
        do {
            // Create conversation with title based on message
            let title = generateConversationTitle(from: message)
            let conversation = try await repository.createConversation(title: title)
            
            // Send the initial message
            await sendMessage(message, in: conversation.id)
            
            return conversation
        } catch {
            self.error = error as? ChatError ?? .invalidResponse
            return nil
        }
    }
    
    /// Loads suggested questions for the current user.
    @MainActor
    public func loadSuggestedQuestions() async {
        guard !isProcessing else { return }
        
        do {
            let userProfile = try? await fetchUserProfile()
            suggestedQuestions = try await claudeService.generateSuggestedQuestions(userProfile: userProfile)
        } catch {
            // Use fallback questions if API fails
            suggestedQuestions = [
                "What does my birth chart reveal about my personality?",
                "How do current planetary transits affect me?",
                "What career paths align with my astrological profile?"
            ]
        }
    }
    
    /// Checks if the user has premium access for unlimited chat.
    public func hasPremiumAccess() async -> Bool {
        // Check if user has active premium subscription
        // This should integrate with your existing commerce/subscription logic
        guard let userProfile = try? await fetchUserProfile() else { return false }
        
        if let expiryDate = userProfile.plusExpiry {
            return expiryDate > Date()
        }
        
        return false
    }
    
    /// Gets the remaining free message count for non-premium users.
    public func getRemainingFreeMessages() async -> Int {
        guard !(await hasPremiumAccess()) else { return Int.max }
        
        // Count messages sent today by the user
        let todayStart = Calendar.current.startOfDay(for: Date())
        let userMessagesToday = repository.currentMessages.filter { message in
            message.role == .user && message.timestamp >= todayStart
        }
        
        let freeLimit = 5 // Allow 5 free messages per day
        return max(0, freeLimit - userMessagesToday.count)
    }
    
    // MARK: - Private Methods
    
    private func fetchUserProfile() async throws -> UserProfile? {
        // This would integrate with your existing user profile fetching logic
        // For now, return nil - you'll need to implement this based on your UserProfile repository
        return nil
    }
    
    private func generateConversationTitle(from message: String) -> String {
        // Generate a title from the first message, truncated if needed
        let maxLength = 50
        let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanMessage.count <= maxLength {
            return cleanMessage
        }
        
        let truncated = String(cleanMessage.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        
        return truncated + "..."
    }
}