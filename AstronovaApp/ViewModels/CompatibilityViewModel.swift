import SwiftUI
import Combine

// MARK: - Compatibility View Model

@MainActor
class CompatibilityViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var compatibilityReport: CompatibilityResponse?
    @Published var isCalculatingCompatibility = false
    @Published var compatibilityError: String?
    @Published var showingCompatibilityError = false
    @Published var partnerBirthData: BirthData?
    
    // MARK: - Dependencies
    
    private let apiServices: APIServicesProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiServices: APIServicesProtocol) {
        self.apiServices = apiServices
    }
    
    // MARK: - Public Methods
    
    func calculateCompatibility(user: BirthData, partner: BirthData) async {
        isCalculatingCompatibility = true
        compatibilityError = nil
        partnerBirthData = partner
        
        do {
            let report = try await apiServices.getCompatibilityReport(person1: user, person2: partner)
            compatibilityReport = report
        } catch {
            compatibilityError = "Failed to calculate compatibility: \(error.localizedDescription)"
            showingCompatibilityError = true
        }
        
        isCalculatingCompatibility = false
    }
    
    func clearCompatibility() {
        compatibilityReport = nil
        partnerBirthData = nil
        compatibilityError = nil
        showingCompatibilityError = false
    }
    
    func clearError() {
        compatibilityError = nil
        showingCompatibilityError = false
    }
    
    // MARK: - Computed Properties
    
    var hasCompatibilityData: Bool {
        return compatibilityReport != nil
    }
    
    var compatibilityScore: Double {
        return compatibilityReport?.compatibility_score ?? 0.0
    }
    
    var compatibilitySummary: String {
        return compatibilityReport?.summary ?? ""
    }
}