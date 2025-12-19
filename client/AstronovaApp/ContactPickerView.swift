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
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.cosmicGold)

            VStack(spacing: 12) {
                Text("Access Your Contacts")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("See compatibility with friends and loved ones based on their birth dates.")
                    .font(.body)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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
                    .font(.headline)
                    .foregroundStyle(Color.cosmicBackground)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cosmicGold, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Access Denied View

    private var accessDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.cosmicTextTertiary)

            VStack(spacing: 12) {
                Text("Contacts Access Denied")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Enable contacts access in Settings to explore compatibility with your contacts.")
                    .font(.body)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundStyle(Color.cosmicGold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cosmicGold, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Contact List View

    private var contactListView: some View {
        VStack(spacing: 0) {
            // Search and filter header
            VStack(spacing: 12) {
                // Search bar
                HStack(spacing: 12) {
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
                .padding(12)
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: 12))

                // Filter toggle
                HStack {
                    Toggle(isOn: $showOnlyWithBirthday) {
                        HStack(spacing: 8) {
                            Image(systemName: "gift")
                                .foregroundStyle(Color.cosmicGold)
                            Text("Only show contacts with birthdays")
                                .font(.subheadline)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.cosmicGold))
                }

                // Stats
                HStack {
                    Text("\(filteredContacts.count) contacts")
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextTertiary)

                    Spacer()

                    if contactsWithBirthdays.count > 0 {
                        Text("\(contactsWithBirthdays.count) with birthdays")
                            .font(.caption)
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
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .padding(.top, 8)
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
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: showOnlyWithBirthday ? "gift.circle" : "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.cosmicTextTertiary)

            if showOnlyWithBirthday {
                Text("No contacts with birthdays")
                    .font(.headline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Add birthdays to your contacts to see them here, or turn off the filter.")
                    .font(.subheadline)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    showOnlyWithBirthday = false
                } label: {
                    Text("Show all contacts")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.cosmicGold)
                }
            } else {
                Text("No contacts found")
                    .font(.headline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Try a different search term.")
                    .font(.subheadline)
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
            HStack(spacing: 14) {
                // Avatar
                contactAvatar

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(contact.fullName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.cosmicTextPrimary)

                        if contact.isPlatformUser {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }

                    if let birthday = contact.birthdayString {
                        HStack(spacing: 4) {
                            Image(systemName: "gift")
                                .font(.caption2)
                            Text(birthday)
                        }
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    } else {
                        Text("No birthday set")
                            .font(.caption)
                            .foregroundStyle(Color.cosmicTextTertiary.opacity(0.6))
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
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
