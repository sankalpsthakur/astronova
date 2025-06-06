import SwiftUI
import CoreLocation
import DataModels
import AuthKit
import CloudKitKit
import AstroEngine

/// Collects birth information after sign-in to complete the user profile with progress tracking.
struct ProfileSetupView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var fullName = ""
    @State private var birthDate = Date()
    @State private var birthTime: Date?
    @State private var includeTime = false
    @State private var birthPlace = ""
    @State private var selectedLocation: CLLocation?
    @State private var isLoading = false
    @State private var showingLocationPicker = false
    @State private var canSkip = false
    
    private var completionPercentage: Double {
        var completed = 0.0
        let total = 4.0
        
        if !fullName.isEmpty { completed += 1 }
        if selectedLocation != nil { completed += 1 }
        if !birthPlace.isEmpty { completed += 1 }
        completed += 1 // Birth date always has a value
        
        return completed / total
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                VStack(spacing: 12) {
                    HStack {
                        Text("Profile Setup")
                            .font(.headline)
                        Spacer()
                        Button("Skip") {
                            Task { await skipSetup() }
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .disabled(isLoading)
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(Int(completionPercentage * 100))% Complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        
                        ProgressView(value: completionPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 2.0)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("Full Name", text: $fullName)
                        
                        DatePicker("Birth Date", 
                                  selection: $birthDate, 
                                  in: ...Date(),
                                  displayedComponents: .date)
                        
                        Toggle("Include Birth Time", isOn: $includeTime)
                        
                        if includeTime {
                            DatePicker("Birth Time", 
                                      selection: Binding(
                                        get: { birthTime ?? Date() },
                                        set: { birthTime = $0 }
                                      ),
                                      displayedComponents: .hourAndMinute)
                        }
                    }
                    
                    Section(header: Text("Birth Location")) {
                        HStack {
                            TextField("City, Country", text: $birthPlace)
                            Button("Search") {
                                showingLocationPicker = true
                            }
                            .disabled(birthPlace.isEmpty)
                        }
                        
                        if let location = selectedLocation {
                            Text("📍 \(location.coordinate.latitude, specifier: "%.2f"), \(location.coordinate.longitude, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section {
                        Button("Complete Setup") {
                            Task { await completeSetup() }
                        }
                        .disabled(!isValid || isLoading)
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationSearchView(query: $birthPlace, selectedLocation: $selectedLocation)
        }
    }
    
    private var isValid: Bool {
        !fullName.isEmpty && selectedLocation != nil
    }
    
    @MainActor
    private func completeSetup() async {
        guard let location = selectedLocation else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Calculate zodiac signs using birth data
            let birthData = BirthData(
                date: birthDate,
                time: includeTime ? Calendar.current.dateComponents([.hour, .minute], from: birthTime ?? Date()) : nil,
                location: location
            )
            
            let calc = WesternCalc()
            let positions = calc.positions(for: birthData)
            
            let sunSign = zodiacSign(for: positions.first(where: { $0.name == "Sun" })?.longitude ?? 0)
            let moonSign = zodiacSign(for: positions.first(where: { $0.name == "Moon" })?.longitude ?? 0)
            let risingSign = zodiacSign(for: positions.first(where: { $0.name == "Ascendant" })?.longitude ?? 0)
            
            // Create complete UserProfile
            let profile = UserProfile(
                fullName: fullName,
                birthDate: birthDate,
                birthTime: includeTime ? Calendar.current.dateComponents([.hour, .minute], from: birthTime ?? Date()) : nil,
                birthPlace: location,
                sunSign: sunSign,
                moonSign: moonSign,
                risingSign: risingSign,
                plusExpiry: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save to CloudKit
            let recordID = try await CKContainer.cosmic.fetchUserRecordID()
            let record = profile.toRecord(in: recordID.zoneID)
            record.recordID = recordID
            try await CKDatabaseProxy.private.saveRecord(record)
            
            // Complete the auth flow
            auth.completeProfileSetup()
            
        } catch {
            print("[ProfileSetupView] Setup failed: \(error)")
        }
    }
    
    @MainActor
    private func skipSetup() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create minimal profile
            let recordID = try await CKContainer.cosmic.fetchUserRecordID()
            let record = CKRecord(recordType: "UserProfile", recordID: recordID)
            record["fullName"] = "Anonymous User" as CKRecordValue
            record["createdAt"] = Date() as CKRecordValue
            record["updatedAt"] = Date() as CKRecordValue
            try await CKDatabaseProxy.private.saveRecord(record)
            
            auth.completeProfileSetup()
        } catch {
            print("[ProfileSetupView] Skip setup failed: \(error)")
        }
    }
    
    
    private func zodiacSign(for longitude: Double) -> String {
        let signs = ["aries", "taurus", "gemini", "cancer", "leo", "virgo",
                    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]
        let index = Int(longitude / 30.0) % 12
        return signs[index]
    }
}

/// Simple location search view for selecting birth place
struct LocationSearchView: View {
    @Binding var query: String
    @Binding var selectedLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [CLPlacemark] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search for a city", text: $query)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit { performSearch() }
                    
                    Button("Search", action: performSearch)
                        .disabled(query.isEmpty || isSearching)
                }
                .padding()
                
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults, id: \.self) { placemark in
                        Button(action: { selectLocation(placemark) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(placemark.locality ?? "Unknown City")
                                    .font(.headline)
                                Text("\(placemark.administrativeArea ?? ""), \(placemark.country ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !query.isEmpty else { return }
        
        isSearching = true
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(query) { placemarks, error in
            DispatchQueue.main.async {
                isSearching = false
                if let placemarks = placemarks {
                    searchResults = Array(placemarks.prefix(10))
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func selectLocation(_ placemark: CLPlacemark) {
        if let location = placemark.location {
            selectedLocation = location
            if let city = placemark.locality,
               let country = placemark.country {
                query = "\(city), \(country)"
            }
        }
        dismiss()
    }
}

extension UserProfile {
    init(fullName: String, birthDate: Date, birthTime: DateComponents?, birthPlace: CLLocation, sunSign: String, moonSign: String, risingSign: String, plusExpiry: Date?, createdAt: Date, updatedAt: Date) {
        self.fullName = fullName
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.sunSign = sunSign
        self.moonSign = moonSign
        self.risingSign = risingSign
        self.plusExpiry = plusExpiry
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}