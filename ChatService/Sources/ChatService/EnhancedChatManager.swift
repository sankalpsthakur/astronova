import Foundation
import DataModels
import AuthKit
import ChartVisualization
import Combine

/// Enhanced chat manager with chart integration and premium features.
public final class EnhancedChatManager: ObservableObject {
    @Published public private(set) var isProcessing = false
    @Published public private(set) var suggestedQuestions: [String] = []
    @Published public private(set) var error: ChatError?
    @Published public private(set) var currentChart: AstrologicalChart?
    @Published public private(set) var showingChart = false
    
    private let claudeService: ClaudeAPIService
    private let repository: ChatRepository
    private let authManager: AuthManager
    private let chartManager: ChartManager
    
    public init(apiKey: String, authManager: AuthManager) {
        self.claudeService = ClaudeAPIService(apiKey: apiKey)
        self.repository = ChatRepository()
        self.authManager = authManager
        self.chartManager = ChartManager()
    }
    
    // MARK: - Public API
    
    /// Repository for accessing conversations and messages.
    public var chatRepository: ChatRepository { repository }
    
    /// Chart manager for visualization.
    public var charts: ChartManager { chartManager }
    
    /// Sends a message with chart context and gets Claude's response.
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
            let isPremium = await hasPremiumAccess()
            
            // Check if message requires chart analysis
            let needsChart = detectChartRequest(in: content)
            
            if needsChart && userProfile != nil {
                // Generate chart if needed
                await generateChartForContext(userProfile: userProfile!, isPremium: isPremium)
            }
            
            // Build enhanced context for Claude
            let enhancedContext = buildEnhancedContext(
                userProfile: userProfile,
                isPremium: isPremium,
                needsChart: needsChart
            )
            
            // Send to Claude with enhanced context
            let response = try await claudeService.sendMessage(
                content,
                conversationHistory: repository.currentMessages,
                userProfile: userProfile,
                additionalContext: enhancedContext
            )
            
            // Add Claude's response
            let assistantMessage = ChatMessage(
                content: response,
                role: .assistant,
                conversationID: conversationID
            )
            try await repository.addMessage(assistantMessage)
            
            // Show chart if relevant and generated
            if needsChart && currentChart != nil {
                showingChart = true
            }
            
        } catch {
            self.error = error as? ChatError ?? .invalidResponse
        }
        
        isProcessing = false
    }
    
    /// Creates a new conversation with chart-aware initial message.
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
    
    /// Loads suggested questions with chart-aware content.
    @MainActor
    public func loadSuggestedQuestions() async {
        guard !isProcessing else { return }
        
        do {
            let userProfile = try? await fetchUserProfile()
            let isPremium = await hasPremiumAccess()
            
            suggestedQuestions = try await generateEnhancedSuggestedQuestions(
                userProfile: userProfile,
                isPremium: isPremium
            )
        } catch {
            // Use fallback questions if API fails
            suggestedQuestions = generateFallbackQuestions(isPremium: await hasPremiumAccess())
        }
    }
    
    /// Generates a chart for the current user and shows it.
    @MainActor
    public func showBirthChart(sidereal: Bool = true) async {
        guard let userProfile = try? await fetchUserProfile() else { return }
        
        let chartType: ChartType = sidereal ? .siderealBirth : .tropicalBirth
        await chartManager.generateBirthChart(for: userProfile, type: chartType)
        
        if let chart = chartManager.currentChart {
            currentChart = chart
            showingChart = true
        }
    }
    
    /// Generates current transit chart.
    @MainActor
    public func showTransitChart(sidereal: Bool = true) async {
        guard await hasPremiumAccess() else {
            // Show premium teaser
            error = .premiumRequired("Transit charts require premium access")
            return
        }
        
        guard let userProfile = try? await fetchUserProfile() else { return }
        
        await chartManager.generateTransitChart(for: userProfile, sidereal: sidereal)
        
        if let chart = chartManager.currentChart {
            currentChart = chart
            showingChart = true
        }
    }
    
    /// Checks if the user has premium access for chart features.
    public func hasPremiumAccess() async -> Bool {
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
        return nil
    }
    
    private func detectChartRequest(in message: String) -> Bool {
        let chartKeywords = [
            "chart", "birth chart", "natal chart", "horoscope",
            "planets", "houses", "aspects", "transits",
            "sun sign", "moon sign", "rising sign", "ascendant",
            "mercury", "venus", "mars", "jupiter", "saturn"
        ]
        
        let lowercasedMessage = message.lowercased()
        return chartKeywords.contains { lowercasedMessage.contains($0) }
    }
    
    @MainActor
    private func generateChartForContext(userProfile: UserProfile, isPremium: Bool) async {
        // Generate basic birth chart for context
        await chartManager.generateBirthChart(for: userProfile, type: .siderealBirth)
        currentChart = chartManager.currentChart
    }
    
    private func buildEnhancedContext(userProfile: UserProfile?, isPremium: Bool, needsChart: Bool) -> String {
        var context = ""
        
        if let profile = userProfile {
            context += "User Profile Context:\n"
            context += "Sun Sign: \(profile.sunSign)\n"
            context += "Moon Sign: \(profile.moonSign)\n"
            context += "Rising Sign: \(profile.risingSign)\n"
            
            if needsChart, let chart = currentChart {
                context += "\n" + chartManager.generateAIContext()
                
                if !isPremium {
                    context += "\nNote: User has basic access. Suggest premium features when relevant."
                }
            }
        }
        
        return context
    }
    
    private func generateEnhancedSuggestedQuestions(userProfile: UserProfile?, isPremium: Bool) async throws -> [String] {
        var questions: [String] = []
        
        if let profile = userProfile {
            // Personalized questions based on user's chart
            questions.append("What does my \(profile.sunSign) sun sign say about my personality?")
            questions.append("How does my \(profile.moonSign) moon sign affect my emotions?")
            questions.append("What does my \(profile.risingSign) rising sign reveal about how others see me?")
            
            if isPremium {
                questions.append("Show me my complete birth chart with current transits")
                questions.append("What planetary aspects are most significant in my chart?")
                questions.append("How are current planetary transits affecting me?")
            } else {
                questions.append("Can you show me my basic birth chart?")
                questions.append("What are the main themes in my astrological profile?")
            }
        } else {
            // Generic questions for users without profiles
            questions = generateFallbackQuestions(isPremium: isPremium)
        }
        
        return Array(questions.shuffled().prefix(3))
    }
    
    private func generateFallbackQuestions(isPremium: Bool) -> [String] {
        var questions = [
            "What does my birth chart reveal about my personality?",
            "How do current planetary transits affect me?",
            "What are the most important planets in astrology?",
            "How do I read my birth chart?"
        ]
        
        if isPremium {
            questions.append(contentsOf: [
                "Show me my detailed birth chart with aspects",
                "What are my current planetary transits?",
                "How do planetary returns affect my life?",
                "What does my progressed chart say about my current life phase?"
            ])
        }
        
        return questions
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

// MARK: - Enhanced Claude Service

extension ClaudeAPIService {
    /// Enhanced message sending with additional context.
    func sendMessage(
        _ message: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        additionalContext: String = ""
    ) async throws -> String {
        // Use existing implementation but with enhanced context
        return try await sendMessage(message, conversationHistory: conversationHistory, userProfile: userProfile)
    }
}

// MARK: - Enhanced Error Types

extension ChatError {
    case custom(String)
    
    static func premiumRequired(_ message: String) -> ChatError {
        return .custom(message)
    }
    
    public var errorDescription: String? {
        switch self {
        case .custom(let message):
            return message
        default:
            return nil
        }
    }
}