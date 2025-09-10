import Foundation
import SwiftUI

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
        storeManager: StoreManagerProtocol = StoreKitManager.shared
    ) {
        self._networkClient = networkClient
        self._storeManager = storeManager
        
        // Initialize APIServices with the provided networkClient
        if let apiServices = apiServices {
            self._apiServices = apiServices
        } else {
            self._apiServices = APIServices(networkClient: networkClient)
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