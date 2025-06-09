import SwiftUI
import Combine

// MARK: - Chart View Model

@MainActor
class ChartViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentChart: ChartResponse?
    @Published var isGeneratingChart = false
    @Published var chartError: String?
    @Published var showingChartError = false
    
    // MARK: - Dependencies
    
    private let apiServices: APIServicesProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiServices: APIServicesProtocol) {
        self.apiServices = apiServices
    }
    
    // MARK: - Public Methods
    
    func generateChart(for profile: UserProfile) async {
        isGeneratingChart = true
        chartError = nil
        
        do {
            let chart = try await apiServices.generateChart(from: profile)
            currentChart = chart
        } catch {
            chartError = "Failed to generate chart: \(error.localizedDescription)"
            showingChartError = true
        }
        
        isGeneratingChart = false
    }
    
    func generateChart(with birthData: BirthData, systems: [String] = ["western", "vedic"]) async {
        isGeneratingChart = true
        chartError = nil
        
        do {
            let chart = try await apiServices.generateChart(birthData: birthData, systems: systems)
            currentChart = chart
        } catch {
            chartError = "Failed to generate chart: \(error.localizedDescription)"
            showingChartError = true
        }
        
        isGeneratingChart = false
    }
    
    func clearChart() {
        currentChart = nil
        chartError = nil
        showingChartError = false
    }
    
    func clearError() {
        chartError = nil
        showingChartError = false
    }
}