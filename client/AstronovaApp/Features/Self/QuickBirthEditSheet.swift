import SwiftUI
import CoreLocation
import MapKit

// MARK: - Quick Birth Edit View
// Compact sheet for editing birth details
// Focused micro-flows for improving chart accuracy

struct QuickBirthEditView: View {
    @EnvironmentObject private var auth: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var birthTime: Date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hasBirthTime: Bool = false
    @State private var birthPlace: String = ""
    @State private var selectedLocation: LocationResult?
    @State private var locationSuggestions: [LocationResult] = []
    @State private var isSearching = false
    @State private var isSaving = false
    @State private var searchTask: Task<Void, Never>?

    private var profile: UserProfile {
        auth.profileManager.profile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicVoid.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Cosmic.Spacing.xl) {
                        // Header
                        headerSection

                        // Name field
                        nameSection

                        // Birth date
                        birthDateSection

                        // Birth time
                        birthTimeSection

                        // Birth place
                        birthPlaceSection

                        // Accuracy indicator
                        accuracyIndicator

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                    .padding(.top, Cosmic.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .foregroundStyle(Color.cosmicGold)
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                }
            }
            .onAppear { loadCurrentProfile() }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 32))
                .foregroundStyle(Color.cosmicGold)

            Text("Tune Your Resonance")
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text("More accurate birth data means\nmore precise cosmic insights")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, Cosmic.Spacing.md)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Name")
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)

            TextField("Your name", text: $fullName)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding(Cosmic.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicStardust.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Birth Date Section

    private var birthDateSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Birth Date")
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)

            DatePicker(
                "",
                selection: $birthDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(Color.cosmicGold)
            .padding(Cosmic.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .fill(Color.cosmicStardust.opacity(0.5))
            )
        }
    }

    // MARK: - Birth Time Section

    private var birthTimeSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack {
                Text("Birth Time")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextTertiary)

                Spacer()

                Toggle("", isOn: $hasBirthTime)
                    .labelsHidden()
                    .tint(Color.cosmicGold)
            }

            if hasBirthTime {
                DatePicker(
                    "",
                    selection: $birthTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .clipped()
                .padding(Cosmic.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicStardust.opacity(0.5))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                HStack {
                    Image(systemName: "clock.badge.questionmark")
                        .foregroundStyle(Color.cosmicWarning)
                    Text("Birth time improves dasha timing accuracy")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(Cosmic.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicWarning.opacity(0.1))
                )
            }
        }
        .onChange(of: hasBirthTime) { _, newValue in
            if newValue && profile.birthTime == nil {
                birthTime = defaultBirthTime(for: birthDate)
            }
        }
        .animation(.cosmicSpring, value: hasBirthTime)
    }

    // MARK: - Birth Place Section

    private var birthPlaceSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Birth Place")
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)

            TextField("Search city...", text: $birthPlace)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding(Cosmic.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicStardust.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: birthPlace) { _, newValue in
                    if selectedLocation?.fullName != newValue {
                        selectedLocation = nil
                    }
                    searchLocations(query: newValue)
                }

            // Search loading indicator
            if isSearching {
                HStack(spacing: Cosmic.Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.cosmicGold)
                    Text("Searching...")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
                .padding(Cosmic.Spacing.sm)
            }

            // Location suggestions
            if !locationSuggestions.isEmpty && !isSearching {
                VStack(spacing: 0) {
                    ForEach(locationSuggestions, id: \.fullName) { location in
                        Button {
                            selectLocation(location)
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.cosmicGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                        .font(.cosmicCallout)
                                        .foregroundStyle(Color.cosmicTextPrimary)
                                    if let state = location.state {
                                        Text("\(state), \(location.country)")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextTertiary)
                                    } else {
                                        Text(location.country)
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextTertiary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(Cosmic.Spacing.sm)
                        }
                        .buttonStyle(.plain)

                        if location.fullName != locationSuggestions.last?.fullName {
                            Divider()
                                .background(Color.cosmicTextTertiary.opacity(0.2))
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicNebula)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: 1)
                )
            }

            // Selected location indicator
            if let location = selectedLocation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.cosmicSuccess)
                    Text("Coordinates locked: \(String(format: "%.2f", location.coordinate.latitude))°, \(String(format: "%.2f", location.coordinate.longitude))°")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(Cosmic.Spacing.sm)
            }
        }
    }

    // MARK: - Accuracy Indicator

    private var accuracyIndicator: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            HStack {
                Text("Chart Accuracy")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Spacer()
                Text("\(accuracyPercentage)%")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(accuracyColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cosmicTextTertiary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accuracyColor.opacity(0.7), accuracyColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(accuracyPercentage) / 100, height: 8)
                }
            }
            .frame(height: 8)

            // Tips
            if accuracyPercentage < 100 {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cosmicGold)
                    Text(accuracyTip)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(Cosmic.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicGold.opacity(0.1))
                )
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicStardust.opacity(0.4))
        )
    }

    // MARK: - Computed Properties

    private var accuracyPercentage: Int {
        var score = 0
        if !fullName.isEmpty { score += 20 }
        if hasBirthTime { score += 40 }
        if selectedLocation != nil || profile.birthLatitude != nil { score += 40 }
        return score
    }

    private var accuracyColor: Color {
        switch accuracyPercentage {
        case 80...100: return .cosmicSuccess
        case 40..<80: return .cosmicWarning
        default: return .cosmicTextTertiary
        }
    }

    private var accuracyTip: String {
        if !hasBirthTime {
            return "Add birth time to unlock precise dasha timing"
        } else if selectedLocation == nil && profile.birthLatitude == nil {
            return "Add birth place to unlock rising sign & lagna"
        } else {
            return "Your chart is ready for accurate readings"
        }
    }

    // MARK: - Actions

    private func loadCurrentProfile() {
        fullName = profile.fullName
        birthDate = profile.birthDate
        if let time = profile.birthTime {
            birthTime = time
            hasBirthTime = true
        } else {
            birthTime = defaultBirthTime(for: profile.birthDate)
        }
        birthPlace = profile.birthPlace ?? ""
        if let lat = profile.birthLatitude, let lon = profile.birthLongitude {
            selectedLocation = LocationResult(
                fullName: profile.birthPlace ?? "Saved Location",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                timezone: profile.timezone ?? ""
            )
        }
    }

    private func searchLocations(query: String) {
        searchTask?.cancel()

        guard query.count >= 2 else {
            locationSuggestions = []
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

            guard !Task.isCancelled else { return }

            do {
                // Use MapKitLocationService for direct MapKit search
                let results = try await MapKitLocationService.shared.searchPlaces(query: query)

                await MainActor.run {
                    locationSuggestions = Array(results.prefix(5))
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    locationSuggestions = []
                    isSearching = false
                }
                #if DEBUG
                print("[QuickBirthEditView] Location search failed: \(error)")
                #endif
            }
        }
    }

    private func selectLocation(_ location: LocationResult) {
        selectedLocation = location
        birthPlace = location.fullName
        locationSuggestions = []
    }

    private func saveChanges() {
        Task {
            await saveChangesAsync()
        }
    }

    @MainActor
    private func saveChangesAsync() async {
        isSaving = true

        #if DEBUG
        print("[QuickBirthEdit] saveChangesAsync called")
        print("[QuickBirthEdit] hasBirthTime: \(hasBirthTime)")
        print("[QuickBirthEdit] birthTime state: \(birthTime)")
        #endif

        let query = birthPlace.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldSavePlace = !query.isEmpty
        var resolvedLocation: LocationResult?

        if let location = selectedLocation {
            resolvedLocation = location
        } else if shouldSavePlace {
            resolvedLocation = await resolveLocation(for: query)
        }

        var updatedProfile = profile
        updatedProfile.fullName = fullName
        updatedProfile.birthDate = birthDate
        updatedProfile.birthTime = hasBirthTime ? birthTime : nil
        if shouldSavePlace {
            updatedProfile.birthPlace = query
        }
        if let location = resolvedLocation {
            updatedProfile.birthPlace = location.fullName
            updatedProfile.birthLatitude = location.coordinate.latitude
            updatedProfile.birthLongitude = location.coordinate.longitude
            updatedProfile.timezone = location.timezone
        }

        auth.profileManager.updateProfile(updatedProfile)

        isSaving = false
        dismiss()
    }

    private func resolveLocation(for query: String) async -> LocationResult? {
        let locations = await auth.profileManager.searchLocations(query: query)
        if let first = locations.first {
            return first
        }

        do {
            let fallback = try await MapKitLocationService.shared.searchPlaces(query: query)
            return fallback.first
        } catch {
            #if DEBUG
            print("[QuickBirthEdit] Failed to resolve location '\(query)': \(error)")
            #endif
            return nil
        }
    }

    private func defaultBirthTime(for date: Date) -> Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    }
}

// MARK: - Preview

#Preview("Quick Birth Edit") {
    QuickBirthEditView()
        .environmentObject(AuthState())
}
