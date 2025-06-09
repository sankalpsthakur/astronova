import SwiftUI
import Combine

// MARK: - Reports View Model

@MainActor
class ReportsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentReport: DetailedReportResponse?
    @Published var isGeneratingReport = false
    @Published var reportError: String?
    @Published var showingReportError = false
    @Published var isPurchasingReport = false
    @Published var purchaseError: String?
    @Published var showingPurchaseError = false
    
    // MARK: - Dependencies
    
    private let apiServices: APIServicesProtocol
    private let storeManager: StoreManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiServices: APIServicesProtocol, storeManager: StoreManagerProtocol) {
        self.apiServices = apiServices
        self.storeManager = storeManager
    }
    
    // MARK: - Public Methods
    
    func generateReport(with birthData: BirthData, type: String) async {
        // Check if user has pro subscription or if they can access this report
        guard canAccessReport(type: type) else {
            await purchaseReport(type: type)
            return
        }
        
        isGeneratingReport = true
        reportError = nil
        
        do {
            let report = try await apiServices.getDetailedReport(birthData: birthData, reportType: type)
            currentReport = report
        } catch {
            reportError = "Failed to generate report: \(error.localizedDescription)"
            showingReportError = true
        }
        
        isGeneratingReport = false
    }
    
    func purchaseReport(type: String) async {
        isPurchasingReport = true
        purchaseError = nil
        
        do {
            let success = await storeManager.purchaseProduct(productId: type)
            if success {
                // Report purchased successfully, now generate it
                // This would typically trigger a UI update to show the report
            } else {
                purchaseError = "Purchase failed. Please try again."
                showingPurchaseError = true
            }
        }
        
        isPurchasingReport = false
    }
    
    func clearReport() {
        currentReport = nil
        reportError = nil
        showingReportError = false
    }
    
    func clearErrors() {
        reportError = nil
        showingReportError = false
        purchaseError = nil
        showingPurchaseError = false
    }
    
    // MARK: - Private Methods
    
    private func canAccessReport(type: String) -> Bool {
        // Check if user has pro subscription
        if storeManager.hasProSubscription {
            return true
        }
        
        // Check if user has purchased this specific report
        // This would require tracking individual report purchases
        // For now, assume they need to purchase each report individually
        return false
    }
}