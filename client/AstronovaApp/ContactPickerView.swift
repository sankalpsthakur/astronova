import SwiftUI

// MARK: - Contact Picker View

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contactsService = ContactsService.shared

    @State private var searchText = ""
    @State private var showOnlyWithBirthday = true

    let onContactSelected: (ContactPerson) -> Void

    private var filteredContacts: [ContactPerson] {
        var result = contactsService.searchContacts(searchText)
        if showOnlyWithBirthday {
            result = result.filter { $0.hasBirthday }
        }
        return result
    }

    private var contactsWithBirthdays: [ContactPerson] {
        contactsService.contactsWithBirthdays()
    }

    var body: some View {
        NavigationStack {
            Group {
                switch contactsService.authorizationStatus {
                case .notDetermined:
                    requestAccessView
                case .denied, .restricted:
                    accessDeniedView
                case .authorized, .limited:
                    contactListView
                @unknown default:
                    requestAccessView
                }
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationTitle("Choose Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
        }
    }

    // MARK: - Request Access View

    private var requestAccessView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            Spacer()

            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.cosmicGold)

            VStack(spacing: Cosmic.Spacing.sm) {
                Text("Access Your Contacts")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("See compatibility with friends and loved ones based on their birth dates.")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Cosmic.Spacing.xl)
            }

            Button {
                Task {
                    let granted = await contactsService.requestAccess()
                    if granted {
                        await contactsService.fetchContacts()
                    }
                }
            } label: {
                Text("Allow Access")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicBackground)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cosmicGold, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            }
            .padding(.horizontal, Cosmic.Spacing.xl)

            Spacer()
        }
    }

    // MARK: - Access Denied View

    private var accessDeniedView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            Spacer()

            Image(systemName: "lock.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.cosmicTextTertiary)

            VStack(spacing: Cosmic.Spacing.sm) {
                Text("Contacts Access Denied")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Enable contacts access in Settings to explore compatibility with your contacts.")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Cosmic.Spacing.xl)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicGold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                            .stroke(Color.cosmicGold, lineWidth: 1)
                    )
            }
            .padding(.horizontal, Cosmic.Spacing.xl)

            Spacer()
        }
    }

    // MARK: - Contact List View

    private var contactListView: some View {
        VStack(spacing: 0) {
            // Search and filter header
            VStack(spacing: Cosmic.Spacing.sm) {
                // Search bar
                HStack(spacing: Cosmic.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.cosmicTextTertiary)

                    TextField("Search contacts", text: $searchText)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.cosmicTextTertiary)
                        }
                    }
                }
                .padding(Cosmic.Spacing.sm)
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))

                // Filter toggle
                HStack {
                    Toggle(isOn: $showOnlyWithBirthday) {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            Image(systemName: "gift")
                                .foregroundStyle(Color.cosmicGold)
                            Text("Only show contacts with birthdays")
                                .font(.cosmicCallout)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.cosmicGold))
                }

                // Stats
                HStack {
                    Text("\(filteredContacts.count) contacts")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)

                    Spacer()

                    if contactsWithBirthdays.count > 0 {
                        Text("\(contactsWithBirthdays.count) with birthdays")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicGold)
                    }
                }
            }
            .padding()

            Divider()
                .background(Color.cosmicNebula)

            // Contact list
            if contactsService.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.cosmicGold)
                    Text("Loading contacts...")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .padding(.top, Cosmic.Spacing.xs)
                    Spacer()
                }
            } else if filteredContacts.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredContacts) { contact in
                            ContactRow(contact: contact) {
                                onContactSelected(contact)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .task {
            if contactsService.contacts.isEmpty {
                await contactsService.fetchContacts()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Spacer()

            Image(systemName: showOnlyWithBirthday ? "gift.circle" : "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.cosmicTextTertiary)

            if showOnlyWithBirthday {
                Text("No contacts with birthdays")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Add birthdays to your contacts to see them here, or turn off the filter.")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Cosmic.Spacing.xl)

                Button {
                    showOnlyWithBirthday = false
                } label: {
                    Text("Show all contacts")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicGold)
                }
            } else {
                Text("No contacts found")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Try a different search term.")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: ContactPerson
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Cosmic.Spacing.sm) {
                // Avatar
                contactAvatar

                // Info
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Text(contact.fullName)
                            .font(.cosmicBodyEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        if contact.isPlatformUser {
                            Image(systemName: "star.fill")
                                .font(.cosmicMicro)
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }

                    if let birthday = contact.birthdayString {
                        HStack(spacing: Cosmic.Spacing.xxs) {
                            Image(systemName: "gift")
                                .font(.cosmicMicro)
                            Text(birthday)
                        }
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    } else {
                        Text("No birthday set")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextTertiary.opacity(0.6))
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(.horizontal, Cosmic.Spacing.md)
            .padding(.vertical, Cosmic.Spacing.sm)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contact.fullName)\(contact.hasBirthday ? ", birthday \(contact.birthdayString ?? "")" : ", no birthday")\(contact.isPlatformUser ? ", Astronova user" : "")")
        .accessibilityHint("Tap to view compatibility")
    }

    @ViewBuilder
    private var contactAvatar: some View {
        if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 44, height: 44)

                Text(contact.initials)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
        }
    }

    private var avatarGradient: LinearGradient {
        // Generate consistent color based on name
        let hash = contact.fullName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0

        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.5, brightness: 0.7),
                Color(hue: hue, saturation: 0.6, brightness: 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    ContactPickerView { contact in
        print("Selected: \(contact.fullName)")
    }
}

#Preview("Contact Row") {
    VStack(spacing: 0) {
        ContactRow(contact: .mock) {}
        Divider()
        ContactRow(contact: .mockPlatformUser) {}
        Divider()
        ContactRow(contact: .mockWithoutBirthday) {}
    }
    .padding()
    .background(Color.cosmicBackground)
}
