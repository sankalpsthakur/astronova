import SwiftUI
import Combine

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