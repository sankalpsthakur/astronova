import SwiftUI
import Combine
import CoreLocation

// MARK: - Main View Model

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedTab: Int = 0
    @Published var selectedSection: String = "overview"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Dependencies
    
    private let apiServices: APIServicesProtocol
    private let storeManager: StoreManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(dependencies: DependencyContainer = .shared) {
        self.apiServices = dependencies.apiServices
        self.storeManager = dependencies.storeManager
        
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    func switchToTab(_ tab: Int) {
        selectedTab = tab
    }
    
    func switchToProfileSection(_ section: String) {
        selectedSection = section
        selectedTab = 2 // Profile tab
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .switchToTab)
            .compactMap { $0.object as? Int }
            .sink { [weak self] tab in
                self?.switchToTab(tab)
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