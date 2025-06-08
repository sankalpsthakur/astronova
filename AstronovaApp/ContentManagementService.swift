import Foundation

struct QuickQuestion: Codable, Identifiable {
    let id: String
    let text: String
    let category: String
    let order: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, text, category, order
        case isActive = "is_active"
    }
}

struct InsightContent: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let category: String
    let priority: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, category, priority
        case isActive = "is_active"
    }
}

struct ContentManagementResponse: Codable {
    let quickQuestions: [QuickQuestion]
    let insights: [InsightContent]
    
    enum CodingKeys: String, CodingKey {
        case quickQuestions = "quick_questions"
        case insights
    }
}

class ContentManagementService {
    static let shared = ContentManagementService()
    
    private let networkClient = NetworkClient.shared
    private var cachedQuickQuestions: [QuickQuestion] = []
    private var cachedInsights: [InsightContent] = []
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    func getQuickQuestions() async throws -> [QuickQuestion] {
        if shouldRefreshCache() {
            try await refreshContent()
        }
        
        if cachedQuickQuestions.isEmpty {
            return getDefaultQuickQuestions()
        }
        
        return cachedQuickQuestions.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    func getInsights() async throws -> [InsightContent] {
        if shouldRefreshCache() {
            try await refreshContent()
        }
        
        if cachedInsights.isEmpty {
            return getDefaultInsights()
        }
        
        return cachedInsights.filter { $0.isActive }.sorted { $0.priority < $1.priority }
    }
    
    private func shouldRefreshCache() -> Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheTimeout
    }
    
    private func refreshContent() async throws {
        do {
            let response = try await networkClient.request(
                endpoint: "/api/v1/content/management",
                responseType: ContentManagementResponse.self
            )
            
            cachedQuickQuestions = response.quickQuestions
            cachedInsights = response.insights
            lastFetchTime = Date()
        } catch {
            print("Failed to fetch content from API, using cached/default content: \(error)")
            if cachedQuickQuestions.isEmpty && cachedInsights.isEmpty {
                throw error
            }
        }
    }
    
    private func getDefaultQuickQuestions() -> [QuickQuestion] {
        return [
            QuickQuestion(id: "1", text: "What's my love forecast? 💖", category: "love", order: 1, isActive: true),
            QuickQuestion(id: "2", text: "Career guidance? ⭐", category: "career", order: 2, isActive: true),
            QuickQuestion(id: "3", text: "Today's energy? ☀️", category: "daily", order: 3, isActive: true),
            QuickQuestion(id: "4", text: "What should I focus on? 🎯", category: "guidance", order: 4, isActive: true),
            QuickQuestion(id: "5", text: "Lucky numbers today? 🍀", category: "daily", order: 5, isActive: true)
        ]
    }
    
    private func getDefaultInsights() -> [InsightContent] {
        return [
            InsightContent(id: "1", title: "Daily Energy", content: "Your cosmic energy forecast", category: "daily", priority: 1, isActive: true),
            InsightContent(id: "2", title: "Love & Relationships", content: "Insights into your romantic journey", category: "love", priority: 2, isActive: true),
            InsightContent(id: "3", title: "Career Path", content: "Professional guidance from the stars", category: "career", priority: 3, isActive: true)
        ]
    }
}