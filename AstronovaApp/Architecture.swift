import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - Architecture Components

// MARK: - Dependency Container

class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    // MARK: - Services
    
    private let _networkClient: NetworkClientProtocol
    private let _apiServices: APIServicesProtocol
    private let _storeManager: StoreManagerProtocol
    
    // MARK: - Initialization
    
    init(
        networkClient: NetworkClientProtocol = NetworkClient(),
        apiServices: APIServicesProtocol? = nil,
        storeManager: StoreManagerProtocol? = nil
    ) {
        self._networkClient = networkClient
        
        // Initialize services with dependency injection
        if let apiServices = apiServices {
            self._apiServices = apiServices
        } else {
            self._apiServices = APIServices(networkClient: networkClient)
        }
        
        if let storeManager = storeManager {
            self._storeManager = storeManager
        } else {
            self._storeManager = StoreKitManager.shared
        }
    }
    
    // MARK: - Service Accessors
    
    var networkClient: NetworkClientProtocol {
        return _networkClient
    }
    
    var apiServices: APIServicesProtocol {
        return _apiServices
    }
    
    var storeManager: StoreManagerProtocol {
        return _storeManager
    }
}

// MARK: - Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func withDependencies(_ container: DependencyContainer = DependencyContainer.shared) -> some View {
        self.environmentObject(container)
            .environment(\.dependencies, container)
    }
}

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case onboarding
    case main
    case profile
    case chartView
    case horoscope(sign: String)
    case reports
    case compatibility
    case detailedReport(type: String, birthData: BirthData)
    case settings
}

// MARK: - Tab Selection

enum TabSelection: Int, CaseIterable {
    case dashboard = 0
    case horoscope = 1
    case profile = 2
    case compatibility = 3
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .horoscope: return "Horoscope"
        case .profile: return "Profile"
        case .compatibility: return "Compatibility"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .horoscope: return "star.fill"
        case .profile: return "person.fill"
        case .compatibility: return "heart.fill"
        }
    }
}

// MARK: - App Coordinator

@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentDestination: NavigationDestination = .main
    @Published var selectedTab: TabSelection = .dashboard
    @Published var navigationPath = NavigationPath()
    @Published var showingSheet: NavigationDestination?
    @Published var showingFullScreenCover: NavigationDestination?
    
    // MARK: - Dependencies
    
    private let dependencies: DependencyContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(dependencies: DependencyContainer = .shared) {
        self.dependencies = dependencies
        setupNotificationObservers()
    }
    
    // MARK: - Navigation Methods
    
    func navigate(to destination: NavigationDestination) {
        currentDestination = destination
        navigationPath.append(destination)
    }
    
    func navigateToTab(_ tab: TabSelection) {
        selectedTab = tab
    }
    
    func presentSheet(_ destination: NavigationDestination) {
        showingSheet = destination
    }
    
    func presentFullScreenCover(_ destination: NavigationDestination) {
        showingFullScreenCover = destination
    }
    
    func dismiss() {
        showingSheet = nil
        showingFullScreenCover = nil
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    // MARK: - Convenience Methods
    
    func switchToProfileSection(_ section: String) {
        selectedTab = .profile
        // Additional logic to navigate to specific profile section
    }
    
    func showHoroscope(for sign: String) {
        selectedTab = .horoscope
        navigate(to: .horoscope(sign: sign))
    }
    
    func showDetailedReport(type: String, birthData: BirthData) {
        navigate(to: .detailedReport(type: type, birthData: birthData))
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .switchToTab)
            .compactMap { $0.object as? Int }
            .compactMap { TabSelection(rawValue: $0) }
            .sink { [weak self] tab in
                self?.navigateToTab(tab)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .switchToProfileSection)
            .compactMap { $0.object as? String }
            .sink { [weak self] section in
                self?.switchToProfileSection(section)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Coordinator Environment

private struct CoordinatorKey: EnvironmentKey {
    static let defaultValue = AppCoordinator()
}

extension EnvironmentValues {
    var coordinator: AppCoordinator {
        get { self[CoordinatorKey.self] }
        set { self[CoordinatorKey.self] = newValue }
    }
}

extension View {
    func withCoordinator(_ coordinator: AppCoordinator) -> some View {
        self.environment(\.coordinator, coordinator)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
}


// MARK: - Mock Services

// MARK: - Mock Network Client

class MockNetworkClient: NetworkClientProtocol {
    var shouldFailRequests = false
    var mockResponses: [String: Any] = [:]
    
    func healthCheck() async throws -> HealthResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        return HealthResponse(
            status: "healthy", 
            message: "Mock service is running"
        )
    }
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        responseType: T.Type
    ) async throws -> T {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        // Return mock response if available
        if let mockResponse = mockResponses[endpoint] as? T {
            return mockResponse
        }
        
        // Create default mock responses
        if responseType == ChartResponse.self {
            let mockChart = ChartResponse(
                chartId: "mock-id",
                charts: [:],
                type: "natal",
                westernChart: nil,
                vedicChart: nil,
                chineseChart: nil
            )
            return mockChart as! T
        }
        
        throw NetworkError.noData
    }
    
    func requestData(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> Data {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return Data()
    }
}

// MARK: - Mock API Services

class MockAPIServices: ObservableObject, APIServicesProtocol {
    private let mockNetworkClient = MockNetworkClient()
    
    var shouldFailRequests = false {
        didSet {
            mockNetworkClient.shouldFailRequests = shouldFailRequests
        }
    }
    
    func healthCheck() async throws -> HealthResponse {
        return try await mockNetworkClient.healthCheck()
    }
    
    func generateChart(birthData: BirthData, systems: [String]) async throws -> ChartResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return ChartResponse(
            chartId: "mock-id",
            charts: [:],
            type: "natal",
            westernChart: nil,
            vedicChart: nil,
            chineseChart: nil
        )
    }
    
    func generateChart(from profile: UserProfile) async throws -> ChartResponse {
        let birthData = try BirthData(from: profile)
        return try await generateChart(birthData: birthData, systems: ["western"])
    }
    
    func getChartAspects(birthData: BirthData) async throws -> Data {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        return Data()
    }
    
    func getHoroscope(sign: String, period: String) async throws -> HoroscopeResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return HoroscopeResponse(
            sign: sign,
            period: period,
            content: "Mock horoscope content for \(sign)",
            date: Date()
        )
    }
    
    func getCompatibilityReport(person1: BirthData, person2: BirthData) async throws -> CompatibilityResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return CompatibilityResponse(
            compatibility_score: 0.75,
            summary: "Mock compatibility summary",
            detailed_analysis: "Mock detailed analysis",
            strengths: ["Communication", "Shared values"],
            challenges: ["Different life goals"]
        )
    }
    
    func getDetailedReport(birthData: BirthData, reportType: String) async throws -> DetailedReportResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return DetailedReportResponse(
            reportId: "mock-report-id",
            type: reportType,
            title: "Mock Report",
            summary: "Mock report summary",
            keyInsights: ["Mock insight 1", "Mock insight 2"],
            downloadUrl: "https://mock.url",
            generatedAt: "2023-01-01T00:00:00Z",
            status: "completed"
        )
    }
    
    func searchLocations(query: String) async throws -> [LocationResult] {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return [
            LocationResult(
                fullName: "Mock City, Mock State, Mock Country",
                coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                timezone: "America/New_York"
            )
        ]
    }
    
    func getCurrentTransits() async throws -> TransitsResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return TransitsResponse(
            date: Date(),
            transits: []
        )
    }
    
    func getChatResponse(messages: [ProtocolChatMessage]) async throws -> ProtocolChatResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return ProtocolChatResponse(
            response: "Mock AI response",
            conversation_id: "mock-conversation-id"
        )
    }
}

// MARK: - Mock Store Manager

class MockStoreManager: ObservableObject, StoreManagerProtocol {
    @Published var hasProSubscription = false
    @Published var products: [String: String] = [
        "love_forecast": "$4.99",
        "birth_chart": "$7.99",
        "career_forecast": "$5.99",
        "year_ahead": "$9.99",
        "astronova_pro_monthly": "$9.99"
    ]
    
    var shouldFailPurchases = false
    
    func loadProducts() {
        // Mock implementation - products are already loaded
    }
    
    func purchaseProduct(productId: String) async -> Bool {
        if shouldFailPurchases {
            return false
        }
        
        if productId == "astronova_pro_monthly" {
            hasProSubscription = true
        }
        
        return true
    }
    
    func hasProduct(_ productId: String) -> Bool {
        if productId == "astronova_pro_monthly" {
            return hasProSubscription
        }
        return true // Mock: assume all products are available
    }
    
    func restorePurchases() async {
        // Mock implementation - do nothing
    }
}

// MARK: - Mock Dependency Container

extension DependencyContainer {
    static var mock: DependencyContainer {
        return DependencyContainer(
            networkClient: MockNetworkClient(),
            apiServices: MockAPIServices(),
            storeManager: MockStoreManager()
        )
    }
}