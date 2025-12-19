import SwiftUI
import MapKit

struct MapKitAutocompleteView: View {
    @Binding var selectedLocation: LocationResult?
    @State private var searchText = ""
    @State private var suggestions: [LocationResult] = []
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
                    ForEach(suggestions, id: \.self) { suggestion in
                        LocationResultRow(location: suggestion) { selectSuggestion(suggestion) }
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
    
    private func selectSuggestion(_ suggestion: LocationResult) {
        searchText = suggestion.fullName
        hideKeyboard()
        suggestions = []

        selectedLocation = suggestion
        onLocationSelected(suggestion)
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
            let results = try await MapKitLocationService.shared.searchPlaces(query: query)
            await MainActor.run { suggestions = Array(results.prefix(8)) }
        } catch {
            #if DEBUG
            debugPrint("[MapKit] Search failed: \(error)")
            #endif
            do {
                let results = try await APIServices.shared.searchLocations(query: query)
                await MainActor.run { suggestions = Array(results.prefix(8)) }
            } catch {
                await MainActor.run { suggestions = [] }
            }
        }

        await MainActor.run {
            isSearching = false
        }
    }
    
    private func hideKeyboard() {
        isSearchFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LocationResultRow: View {
    let location: LocationResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.fullName)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(location.timezone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
