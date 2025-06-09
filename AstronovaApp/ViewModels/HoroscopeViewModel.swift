import SwiftUI
import Combine

// MARK: - Horoscope View Model

@MainActor
class HoroscopeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentHoroscope: HoroscopeResponse?
    @Published var selectedPeriod: String = "daily"
    @Published var isLoadingHoroscope = false
    @Published var horoscopeError: String?
    @Published var showingHoroscopeError = false
    
    // MARK: - Dependencies
    
    private let apiServices: APIServicesProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiServices: APIServicesProtocol) {
        self.apiServices = apiServices
    }
    
    // MARK: - Public Methods
    
    func loadHoroscope(for sign: String, period: String? = nil) async {
        let periodToUse = period ?? selectedPeriod
        isLoadingHoroscope = true
        horoscopeError = nil
        
        do {
            let horoscope = try await apiServices.getHoroscope(sign: sign, period: periodToUse)
            currentHoroscope = horoscope
            selectedPeriod = periodToUse
        } catch {
            horoscopeError = "Failed to load horoscope: \(error.localizedDescription)"
            showingHoroscopeError = true
        }
        
        isLoadingHoroscope = false
    }
    
    func changePeriod(to period: String, for sign: String) async {
        selectedPeriod = period
        await loadHoroscope(for: sign, period: period)
    }
    
    func clearHoroscope() {
        currentHoroscope = nil
        horoscopeError = nil
        showingHoroscopeError = false
    }
    
    func clearError() {
        horoscopeError = nil
        showingHoroscopeError = false
    }
}