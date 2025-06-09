import SwiftUI
import CoreLocation

struct GooglePlacesAutocompleteView: View {
    @Binding var selectedLocation: LocationResult?
    @State private var searchText = ""
    @State private var predictions: [GooglePlaceAutocomplete] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool
    
    let onLocationSelected: (LocationResult) -> Void
    let placeholder: String
    
    init(
        selectedLocation: Binding<LocationResult?>,
        placeholder: String = "Search for a location...",
        onLocationSelected: @escaping (LocationResult) -> Void
    ) {
        self._selectedLocation = selectedLocation
        self.placeholder = placeholder
        self.onLocationSelected = onLocationSelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField(placeholder, text: $searchText)
                    .focused($isSearchFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        debounceAutocomplete(newValue)
                    }
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !searchText.isEmpty {
                    Button {
                        clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Autocomplete results
            if !predictions.isEmpty && isSearchFocused {
                VStack(spacing: 0) {
                    ForEach(predictions, id: \.placeId) { prediction in
                        GooglePlacePredictionRow(prediction: prediction) {
                            selectPrediction(prediction)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
            }
        }
    }
    
    private func clearSearch() {
        searchText = ""
        predictions = []
        selectedLocation = nil
        isSearchFocused = false
    }
    
    private func selectPrediction(_ prediction: GooglePlaceAutocomplete) {
        searchText = prediction.description
        isSearchFocused = false
        predictions = []
        
        // Get place details to get coordinates
        Task {
            do {
                let details = try await GooglePlacesService.shared.getPlaceDetails(placeId: prediction.placeId)
                
                let locationResult = LocationResult(
                    fullName: details.formattedAddress,
                    coordinate: CLLocationCoordinate2D(
                        latitude: details.geometry.location.lat,
                        longitude: details.geometry.location.lng
                    ),
                    timezone: timezoneFromUTCOffset(details.utcOffset)
                )
                
                await MainActor.run {
                    selectedLocation = locationResult
                    onLocationSelected(locationResult)
                }
            } catch {
                print("Failed to get place details: \(error)")
                
                // Fallback - create location without detailed info
                let fallbackLocation = LocationResult(
                    fullName: prediction.description,
                    coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Will need to be resolved
                    timezone: TimeZone.current.identifier
                )
                
                await MainActor.run {
                    selectedLocation = fallbackLocation
                    onLocationSelected(fallbackLocation)
                }
            }
        }
    }
    
    private func debounceAutocomplete(_ query: String) {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, query.count >= 2 else {
            predictions = []
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            if !Task.isCancelled {
                await performAutocomplete(query)
            }
        }
    }
    
    private func performAutocomplete(_ query: String) async {
        guard !query.isEmpty else { return }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let results = try await GooglePlacesService.shared.autocomplete(input: query)
            
            await MainActor.run {
                predictions = results
                isSearching = false
            }
        } catch {
            print("Autocomplete failed: \(error)")
            
            await MainActor.run {
                predictions = []
                isSearching = false
            }
        }
    }
    
    private func timezoneFromUTCOffset(_ utcOffset: Int?) -> String {
        guard let offset = utcOffset else {
            return TimeZone.current.identifier
        }
        
        // Convert minutes to seconds
        let offsetSeconds = offset * 60
        
        // Find timezone with matching offset
        for identifier in TimeZone.knownTimeZoneIdentifiers {
            if let timezone = TimeZone(identifier: identifier),
               timezone.secondsFromGMT() == offsetSeconds {
                return identifier
            }
        }
        
        return TimeZone.current.identifier
    }
}

struct GooglePlacePredictionRow: View {
    let prediction: GooglePlaceAutocomplete
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let formatting = prediction.structuredFormatting {
                        Text(formatting.mainText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let secondaryText = formatting.secondaryText {
                            Text(secondaryText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(prediction.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 48)
    }
}

#Preview {
    VStack {
        GooglePlacesAutocompleteView(
            selectedLocation: .constant(nil),
            placeholder: "Where were you born?"
        ) { location in
            print("Selected: \(location)")
        }
        
        Spacer()
    }
    .padding()
}