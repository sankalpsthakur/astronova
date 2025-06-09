import SwiftUI
import MapKit
import CoreLocation

struct MapKitLocationPicker: View {
    @Binding var selectedLocation: LocationResult?
    @State private var searchText = ""
    @State private var searchResults: [LocationResult] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @FocusState private var isSearchFocused: Bool
    
    let onLocationSelected: (LocationResult) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for a location...", text: $searchText)
                        .focused($isSearchFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit {
                            performSearch()
                        }
                        .onChange(of: searchText) { _, newValue in
                            debounceSearch(newValue)
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Search results
                if !searchResults.isEmpty && isSearchFocused {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults, id: \.fullName) { location in
                                LocationResultRow(location: location) {
                                    selectLocation(location)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Map view
            Map(coordinateRegion: $region, 
                interactionModes: [.all],
                showsUserLocation: true,
                annotationItems: selectedCoordinate.map { [MapAnnotation(coordinate: $0)] } ?? []) { annotation in
                MapPin(coordinate: annotation.coordinate, tint: .red)
            }
            .onTapGesture(coordinateSpace: .local) { location in
                // Convert tap location to coordinate
                let mapFrame = UIScreen.main.bounds
                let x = location.x / mapFrame.width
                let y = location.y / mapFrame.height
                
                let longitude = region.center.longitude + (x - 0.5) * region.span.longitudeDelta
                let latitude = region.center.latitude - (y - 0.5) * region.span.latitudeDelta
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                handleMapTap(at: coordinate)
            }
            .frame(minHeight: 300)
        }
        .navigationTitle("Select Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            requestLocationPermission()
        }
    }
    
    private func selectLocation(_ location: LocationResult) {
        selectedLocation = location
        selectedCoordinate = location.coordinate
        searchText = location.fullName
        isSearchFocused = false
        
        // Update map region
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        onLocationSelected(location)
    }
    
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        
        // Reverse geocode the coordinate using MapKitLocationService
        Task {
            do {
                let locationResult = try await MapKitLocationService.shared.reverseGeocode(coordinate: coordinate)
                
                await MainActor.run {
                    selectLocation(locationResult)
                }
            } catch {
                print("Reverse geocoding failed: \(error)")
                
                // Fallback location
                let fallbackLocation = LocationResult(
                    fullName: "Selected Location",
                    coordinate: coordinate,
                    timezone: TimeZone.current.identifier
                )
                
                await MainActor.run {
                    selectLocation(fallbackLocation)
                }
            }
        }
    }
    
    
    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            
            if !Task.isCancelled {
                await performLocationSearch(query)
            }
        }
    }
    
    private func performSearch() {
        Task {
            await performLocationSearch(searchText)
        }
    }
    
    private func performLocationSearch(_ query: String) async {
        guard !query.isEmpty else { return }
        
        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }
        
        do {
            // Use MapKit for location search
            let results = try await MapKitLocationService.shared.searchPlaces(query: query)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
                errorMessage = results.isEmpty ? "No locations found" : nil
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isSearching = false
                errorMessage = "Search failed. Please try again."
            }
            print("MapKit location search failed: \(error)")
        }
    }
    
    private func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
}

struct LocationResultRow: View {
    let location: LocationResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.fullName)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 16)
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    NavigationStack {
        MapKitLocationPicker(selectedLocation: .constant(nil)) { location in
            print("Selected: \(location)")
        }
    }
}