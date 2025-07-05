import SwiftUI
import MapKit
import Combine

struct MapKitAutocompleteView: View {
    @Binding var selectedLocation: LocationResult?
    @State private var searchText = ""
    @State private var suggestions: [LocationSuggestion] = []
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
        
        // Initialize search text with placeholder if it contains existing location
        if placeholder != "Search for a location..." && placeholder != "City, State/Country" {
            self._searchText = State(initialValue: placeholder)
        }
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
            
            // Autocomplete suggestions
            if !suggestions.isEmpty && isSearchFocused {
                VStack(spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        LocationSuggestionRow(suggestion: suggestion) {
                            selectSuggestion(suggestion)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
            }
        }
        .onTapGesture {
            // Prevents tap from dismissing keyboard when tapping on the field itself
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { _ in
                    hideKeyboard()
                }
        )
    }
    
    private func clearSearch() {
        searchText = ""
        suggestions = []
        selectedLocation = nil
        isSearchFocused = false
        searchTask?.cancel()
    }
    
    private func selectSuggestion(_ suggestion: LocationSuggestion) {
        searchText = suggestion.displayText
        hideKeyboard()
        suggestions = []
        
        // Get full location details from the completion using MapKitLocationService
        Task {
            do {
                let locationResult = try await MapKitLocationService.shared.getLocationFromCompletion(suggestion.completion)
                
                await MainActor.run {
                    selectedLocation = locationResult
                    onLocationSelected(locationResult)
                }
            } catch {
                print("Failed to get location details: \(error)")
                await handleFallbackSelection(suggestion)
            }
        }
    }
    
    private func handleFallbackSelection(_ suggestion: LocationSuggestion) async {
        // Fallback - create location without detailed coordinates
        let fallbackLocation = LocationResult(
            fullName: suggestion.displayText,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timezone: TimeZone.current.identifier
        )
        
        await MainActor.run {
            selectedLocation = fallbackLocation
            onLocationSelected(fallbackLocation)
        }
    }
    
    private func debounceAutocomplete(_ query: String) {
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            suggestions = []
            isSearching = false
            return
        }
        
        guard trimmedQuery.count >= 2 else {
            suggestions = []
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            if !Task.isCancelled {
                await performAutocomplete(trimmedQuery)
            }
        }
    }
    
    private func performAutocomplete(_ query: String) async {
        guard !query.isEmpty else { return }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let results = try await MapKitLocationService.shared.autocomplete(input: query)
            
            await MainActor.run {
                suggestions = results
                isSearching = false
            }
        } catch {
            print("Autocomplete failed: \(error)")
            
            await MainActor.run {
                suggestions = []
                isSearching = false
            }
        }
    }
    
    private func hideKeyboard() {
        isSearchFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LocationSuggestionRow: View {
    let suggestion: LocationSuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let subtitle = suggestion.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
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
        MapKitAutocompleteView(
            selectedLocation: .constant(nil),
            placeholder: "Where were you born?"
        ) { location in
            print("Selected: \(location)")
        }
        
        Spacer()
    }
    .padding()
}