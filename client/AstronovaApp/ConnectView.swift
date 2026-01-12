import SwiftUI

// MARK: - Connect View
// The relationships list - reduce friction to start a relationship reading.
// Search + Quick Add carousel + Relationship cards with pulse glyphs.

struct ConnectView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var searchText = ""
    @State private var relationships: [RelationshipProfile] = []
    @State private var selectedRelationship: RelationshipProfile?
    @State private var showAddSheet = false
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var refreshing = false
    @StateObject private var contactsService = ContactsService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBackground.ignoresSafeArea()

                if !auth.isAuthenticated {
                    AuthRequiredView(
                        title: "Sign in to connect",
                        message: "Create and sync relationships across your devices."
                    )
                } else if isLoading && relationships.isEmpty {
                    loadingView
                } else if let error = loadError, relationships.isEmpty {
                    errorView(error)
                } else if relationships.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .searchable(text: $searchText, prompt: "Search people")
            .navigationTitle("Connect")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.cosmicGold)
                    }
                    .accessibilityLabel("Add new relationship")
                    .accessibilityHint("Create a compatibility analysis")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddRelationshipSheet(onSave: { newRelationship in
                    relationships.insert(newRelationship, at: 0)
                })
            }
            .navigationDestination(item: $selectedRelationship) { profile in
                RelationshipDetailView(profile: profile)
            }
            .task {
                guard auth.isAuthenticated else { return }
                await loadRelationships()
                await contactsService.fetchContacts()
            }
            .refreshable {
                guard auth.isAuthenticated else { return }
                await loadRelationships()
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Add carousel
                quickAddSection

                // Your relationships
                relationshipsSection
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.cosmicGold)
            Text("Loading connections...")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading connections")
        .accessibilityValue("In progress")
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicWarning)

            Text("Couldn't load connections")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(error.localizedDescription)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Cosmic.Spacing.xl)

            Button {
                Task { await loadRelationships() }
            } label: {
                Text("Try Again")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.lg)
                    .padding(.vertical, Cosmic.Spacing.sm)
                    .background(Color.cosmicGold.opacity(0.15), in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Couldn't load connections. \(error.localizedDescription)")
        .accessibilityHint("Double tap Try Again to reload")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cosmicGold, Color.cosmicAmethyst],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Cosmic.Spacing.xs) {
                Text("No connections yet")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Add someone to explore your compatibility")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
                CosmicHaptics.light()
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Connection")
                }
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicVoid)
                .padding(.horizontal, Cosmic.Spacing.lg)
                .padding(.vertical, Cosmic.Spacing.md)
                .background(
                    LinearGradient.cosmicAntiqueGold,
                    in: Capsule()
                )
            }
        }
        .padding(Cosmic.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No connections yet. Add someone to explore your compatibility.")
        .accessibilityHint("Double tap Add Your First Connection to get started")
    }

    // MARK: - Load Relationships

    private func loadRelationships() async {
        if !refreshing {
            isLoading = true
        }
        loadError = nil

        do {
            relationships = try await APIServices.shared.listRelationships()
        } catch {
            loadError = error
            #if DEBUG
            print("[ConnectView] Failed to load relationships: \(error)")
            #endif
        }

        isLoading = false
        refreshing = false
    }

    // MARK: - Quick Add Section

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Quick add")
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.sm) {
                    // Add custom chart
                    QuickAddCard(
                        icon: "lock.fill",
                        title: "Add a custom\nfriend chart",
                        isLocked: false,
                        action: { showAddSheet = true }
                    )

                    // Suggested contacts from device
                    ForEach(suggestedContacts) { contact in
                        SuggestedContactCard(
                            contact: contact,
                            onAdd: {
                                // Pre-fill add sheet with contact info
                                showAddSheet = true
                                CosmicHaptics.success()
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    /// Suggested contacts from device - prioritizes those with birthdays
    private var suggestedContacts: [ContactPerson] {
        // Filter out contacts already in relationships
        let existingNames = Set(relationships.map { $0.name.lowercased() })
        let available = contactsService.contacts.filter { contact in
            !existingNames.contains(contact.fullName.lowercased())
        }
        // Prioritize contacts with birthdays (more useful for astrology)
        let withBirthdays = available.filter { $0.hasBirthday }
        let suggestions = withBirthdays.isEmpty ? Array(available.prefix(5)) : Array(withBirthdays.prefix(5))
        return suggestions
    }

    // MARK: - Relationships Section

    private var relationshipsSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Your connections")
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: 0) {
                ForEach(filteredRelationships) { relationship in
                    RelationshipRow(
                        profile: relationship,
                        onTap: {
                            selectedRelationship = relationship
                            CosmicHaptics.light()
                        }
                    )

                    if relationship.id != filteredRelationships.last?.id {
                        Divider()
                            .background(Color.cosmicTextTertiary.opacity(0.3))
                            .padding(.leading, 72)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cosmicSurface)
            )
            .padding(.horizontal)
        }
    }

    private var filteredRelationships: [RelationshipProfile] {
        if searchText.isEmpty {
            return relationships
        }
        return relationships.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Quick Add Card

struct QuickAddCard: View {
    let icon: String
    let title: String
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Cosmic.Spacing.xs) {
                ZStack {
                    Circle()
                        .stroke(Color.cosmicTextTertiary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)

                Text("ADD")
                    .font(.cosmicMicro)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cosmicBackground)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.cosmicTextPrimary)
                    )
            }
            .frame(width: 100)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
        .accessibilityHint(isLocked ? "Locked feature" : "Double tap to add a new connection")
    }
}

// MARK: - Suggested Person Card

struct SuggestedPersonCard: View {
    let name: String
    let handle: String
    let onAdd: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Cosmic.Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                // Avatar placeholder
                Circle()
                    .fill(Color.cosmicSurface)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    )
                    .accessibilityHidden(true)

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.cosmicMicro)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .padding(4)
                        .background(Circle().fill(Color.cosmicStardust))
                }
                .accessibleIconButton()
                .accessibilityLabel("Dismiss suggestion")
                .accessibilityHint("Removes this suggestion")
                .offset(x: 4, y: -4)
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)

                Text(handle)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .lineLimit(1)
            }
            .frame(width: 80)

            Button(action: onAdd) {
                Text("ADD")
                    .font(.cosmicMicro)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cosmicBackground)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.cosmicTextPrimary)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(name)")
            .accessibilityHint("Creates a relationship profile")
        }
        .frame(width: 100)
    }
}

// MARK: - Suggested Contact Card (from device contacts)

struct SuggestedContactCard: View {
    let contact: ContactPerson
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Cosmic.Spacing.xs) {
            // Avatar with contact image or initials
            if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            } else {
                Circle()
                    .fill(Color.cosmicSurface)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(contact.initials)
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    )
                    .accessibilityHidden(true)
            }

            VStack(spacing: 2) {
                Text(contact.fullName)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)

                if let birthday = contact.birthdayString {
                    Text(birthday)
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicGold)
                        .lineLimit(1)
                } else {
                    Text("Add birthday")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 80)

            Button(action: onAdd) {
                Text("ADD")
                    .font(.cosmicMicro)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cosmicBackground)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.cosmicTextPrimary)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(contact.fullName)")
            .accessibilityHint("Creates a relationship profile")
        }
        .frame(width: 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contact.fullName). \(contact.birthdayString ?? "Birthday not set")")
    }
}

// MARK: - Relationship Row

struct RelationshipRow: View {
    let profile: RelationshipProfile
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Cosmic.Spacing.sm) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cosmicGold.opacity(0.3), Color.cosmicAmethyst.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(profile.name.prefix(1)))
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(profile.name)
                        .font(.cosmicBodyEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(profile.signSummary)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    if let signature = profile.sharedSignature {
                        Text(signature)
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Pulse glyph
                if let pulse = profile.lastPulse {
                    RelationshipPulseView(pulse: pulse, isCompact: true, showLabel: false)
                }

                Image(systemName: "chevron.right")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Cosmic.Spacing.md)
            .padding(.vertical, Cosmic.Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Relationship with \(profile.name). \(profile.signSummary). \(pulseAccessibilityLabel)")
        .accessibilityHint("Double tap to view detailed compatibility analysis")
        .accessibilityAddTraits(.isButton)
    }

    private var pulseAccessibilityLabel: String {
        guard let pulse = profile.lastPulse else { return "" }
        return "Current energy: \(pulse.label)."
    }
}

// MARK: - Add Relationship Sheet

struct AddRelationshipSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: ((RelationshipProfile) -> Void)?

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var birthTime = Date()
    @State private var birthPlace = ""
    @State private var selectedLocation: LocationResult?
    @State private var includeTime = false
    @State private var showContactPicker = false
    @State private var importedContact: ContactPerson?
    @State private var isSaving = false
    @State private var saveError: String?

    // Location search
    @State private var locationSuggestions: [LocationResult] = []
    @State private var isSearchingLocation = false
    @State private var locationSearchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Import from Contacts card
                    importFromContactsCard

                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .fill(Color.cosmicNebula)
                            .frame(height: 1)
                        Text("or enter manually")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Rectangle()
                            .fill(Color.cosmicNebula)
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Manual entry form
                    VStack(spacing: 16) {
                        // Basic Info Section
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                            Text("Basic Info")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextTertiary)
                                .accessibilityAddTraits(.isHeader)

                            TextField("Name", text: $name)
                                .textFieldStyle(CosmicTextFieldStyle())
                                .accessibilityLabel("Partner name")

                            DatePicker("Birth Date", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .tint(Color.cosmicGold)
                                .accessibilityLabel("Partner birth date")
                                .accessibilityHint("Select the birth date")
                        }

                        // Birth Time Section
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                            Text("Birth Time (Optional)")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextTertiary)
                                .accessibilityAddTraits(.isHeader)

                            Toggle("Include birth time", isOn: $includeTime)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .tint(Color.cosmicGold)
                                .accessibilityHint("Turn on to enter a birth time")

                            if includeTime {
                                DatePicker("Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .tint(Color.cosmicGold)
                                    .accessibilityLabel("Birth time")
                            }
                        }

                        // Birth Place Section
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                            Text("Birth Place (Optional)")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextTertiary)
                                .accessibilityAddTraits(.isHeader)

                            TextField("City, Country", text: $birthPlace)
                                .textFieldStyle(CosmicTextFieldStyle())
                                .onChange(of: birthPlace) { _, newValue in
                                    searchLocation(query: newValue)
                                }
                                .accessibilityLabel("Birth location")
                                .accessibilityHint("Start typing to search for cities")

                            if isSearchingLocation {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(Color.cosmicGold)
                                    Text("Searching...")
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextTertiary)
                                }
                                .padding(.leading, Cosmic.Spacing.xxs)
                            }

                            if !locationSuggestions.isEmpty {
                                locationSuggestionsView
                            }
                        }

                        // Error message
                        if let error = saveError {
                            Text(error)
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicError)
                                .padding(.top, Cosmic.Spacing.xxs)
                        }
                    }
                    .padding()
                    .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color.cosmicBackground)
            .navigationTitle("Add Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                            .tint(Color.cosmicGold)
                    } else {
                        Button("Add") {
                            Task { await saveRelationship() }
                        }
                        .foregroundStyle(name.isEmpty ? Color.cosmicTextTertiary : Color.cosmicGold)
                        .disabled(name.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { contact in
                    importedContact = contact
                    name = contact.fullName
                    if let birthday = contact.birthdayDate {
                        birthDate = birthday
                    }
                }
            }
        }
    }

    // MARK: - Save Relationship

    private func saveRelationship() async {
        isSaving = true
        saveError = nil

        do {
            let newRelationship = try await APIServices.shared.createRelationship(
                name: name,
                birthDate: birthDate,
                birthTime: includeTime ? birthTime : nil,
                timezone: selectedLocation != nil ? TimeZone.current.identifier : nil,
                latitude: selectedLocation?.latitude,
                longitude: selectedLocation?.longitude,
                locationName: selectedLocation != nil ? birthPlace : nil
            )

            await MainActor.run {
                CosmicHaptics.success()
                onSave?(newRelationship)
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = "Failed to save: \(error.localizedDescription)"
                CosmicHaptics.error()
                isSaving = false
            }
        }
    }

    // MARK: - Location Search

    private func searchLocation(query: String) {
        locationSearchTask?.cancel()
        selectedLocation = nil

        guard query.count >= 2 else {
            locationSuggestions = []
            return
        }

        isSearchingLocation = true

        locationSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }

            do {
                let results = try await MapKitLocationService.shared.searchPlaces(query: query)
                await MainActor.run {
                    locationSuggestions = Array(results.prefix(5))
                    isSearchingLocation = false
                }
            } catch {
                await MainActor.run {
                    locationSuggestions = []
                    isSearchingLocation = false
                }
            }
        }
    }

    private func selectLocation(_ location: LocationResult) {
        selectedLocation = location
        birthPlace = location.displayName
        locationSuggestions = []
        CosmicHaptics.light()
    }

    // MARK: - Import from Contacts Card

    private var importFromContactsCard: some View {
        Button {
            showContactPicker = true
            CosmicHaptics.light()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.cosmicGold.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundStyle(Color.cosmicGold)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Import from Contacts")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("Quick-add from your phone contacts")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cosmicSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cosmicGold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Import from Contacts")
        .accessibilityHint("Choose a contact to prefill birth details")
    }

    // MARK: - Location Suggestions View

    @ViewBuilder
    private var locationSuggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(locationSuggestions, id: \.self) { location in
                locationRow(for: location)
                if location != locationSuggestions.last {
                    Divider()
                        .background(Color.cosmicNebula)
                }
            }
        }
        .background(Color.cosmicSurfaceSecondary, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func locationRow(for location: LocationResult) -> some View {
        Button {
            selectLocation(location)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    locationSubtitle(for: location)
                }
                Spacer()
                if selectedLocation == location {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.cosmicGold)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Cosmic.Spacing.xs)
            .padding(.horizontal, Cosmic.Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Location \(location.displayName)")
        .accessibilityHint("Select this location")
        .accessibilityAddTraits(selectedLocation == location ? [.isSelected] : [])
    }

    @ViewBuilder
    private func locationSubtitle(for location: LocationResult) -> some View {
        if let state = location.state {
            Text("\(state), \(location.country)")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        } else {
            Text(location.country)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }
}

// MARK: - Cosmic Text Field Style

struct CosmicTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.cosmicSurfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(Color.cosmicTextPrimary)
    }
}

// MARK: - Mock Data

extension RelationshipProfile {
    static var mockList: [RelationshipProfile] {
        [
            RelationshipProfile(
                id: "1",
                name: "Niharika",
                avatarUrl: nil,
                sunSign: "Capricorn",
                moonSign: "Cancer",
                risingSign: "Gemini",
                birthDate: Date(),
                sharedSignature: "Warmth + honesty, watch power dynamics",
                lastPulse: RelationshipPulse(state: .flowing, intensity: .strong, label: "Flowing", topActivations: []),
                lastViewed: Date()
            ),
            RelationshipProfile(
                id: "2",
                name: "Arjun",
                avatarUrl: nil,
                sunSign: "Leo",
                moonSign: "Aries",
                risingSign: "Scorpio",
                birthDate: Date(),
                sharedSignature: "Fire meets intensity",
                lastPulse: RelationshipPulse(state: .electric, intensity: .intense, label: "Electric", topActivations: []),
                lastViewed: Date()
            ),
            RelationshipProfile(
                id: "3",
                name: "Priya",
                avatarUrl: nil,
                sunSign: "Pisces",
                moonSign: "Taurus",
                risingSign: nil,
                birthDate: Date(),
                sharedSignature: nil,
                lastPulse: RelationshipPulse(state: .grounded, intensity: .moderate, label: "Grounded", topActivations: []),
                lastViewed: nil
            )
        ]
    }
}

// MARK: - Preview

#Preview {
    ConnectView()
}
