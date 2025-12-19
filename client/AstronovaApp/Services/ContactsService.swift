import Foundation
import Contacts

// MARK: - Contact Person Model

struct ContactPerson: Identifiable, Hashable {
    let id: String
    let fullName: String
    let givenName: String
    let familyName: String
    let birthday: DateComponents?
    let imageData: Data?
    let isPlatformUser: Bool
    let platformUserId: String?

    var hasBirthday: Bool {
        guard let birthday = birthday,
              let month = birthday.month,
              let day = birthday.day else { return false }
        return month > 0 && day > 0
    }

    var birthdayDate: Date? {
        guard let birthday = birthday else { return nil }
        return Calendar.current.date(from: birthday)
    }

    var birthdayString: String? {
        guard let birthday = birthday,
              let month = birthday.month,
              let day = birthday.day else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"

        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = birthday.year ?? 2000

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return nil
    }

    var initials: String {
        let first = givenName.first.map(String.init) ?? ""
        let last = familyName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

// MARK: - Contacts Service

final class ContactsService: ObservableObject {
    static let shared = ContactsService()

    @Published private(set) var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published private(set) var contacts: [ContactPerson] = []
    @Published private(set) var isLoading = false

    private let store = CNContactStore()
    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    func updateAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                updateAuthorizationStatus()
            }
            return granted
        } catch {
            #if DEBUG
            debugPrint("[Contacts] Access error: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Fetching Contacts

    @MainActor
    func fetchContacts() async {
        let hasAccess: Bool
        if #available(iOS 18.0, *) {
            hasAccess = authorizationStatus == .authorized || authorizationStatus == .limited
        } else {
            hasAccess = authorizationStatus == .authorized
        }
        guard hasAccess else { return }

        isLoading = true
        defer { isLoading = false }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName

        var fetchedContacts: [ContactPerson] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let person = ContactPerson(
                    id: contact.identifier,
                    fullName: CNContactFormatter.string(from: contact, style: .fullName) ?? "\(contact.givenName) \(contact.familyName)",
                    givenName: contact.givenName,
                    familyName: contact.familyName,
                    birthday: contact.birthday,
                    imageData: contact.thumbnailImageData,
                    isPlatformUser: false, // Will be updated by platform check
                    platformUserId: nil
                )
                fetchedContacts.append(person)
            }

            // Sort: contacts with birthdays first, then alphabetically
            contacts = fetchedContacts.sorted { a, b in
                if a.hasBirthday && !b.hasBirthday { return true }
                if !a.hasBirthday && b.hasBirthday { return false }
                return a.fullName.localizedCaseInsensitiveCompare(b.fullName) == .orderedAscending
            }
        } catch {
            #if DEBUG
            debugPrint("[Contacts] Error fetching contacts: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Filtering

    func contactsWithBirthdays() -> [ContactPerson] {
        contacts.filter { $0.hasBirthday }
    }

    func searchContacts(_ query: String) -> [ContactPerson] {
        guard !query.isEmpty else { return contacts }
        let lowercased = query.lowercased()
        return contacts.filter { contact in
            contact.fullName.lowercased().contains(lowercased) ||
            contact.givenName.lowercased().contains(lowercased) ||
            contact.familyName.lowercased().contains(lowercased)
        }
    }

    // MARK: - Platform User Detection (Placeholder)

    /// Check which contacts are platform users
    /// This would typically call an API endpoint with hashed contact identifiers
    func checkPlatformUsers(_ contactIds: [String]) async -> [String: String] {
        // TODO: Implement API call to check platform users
        // Returns mapping of contact ID -> platform user ID
        // For now, return empty (no platform users detected)
        return [:]
    }

    /// Update contacts with platform user status
    @MainActor
    func updatePlatformUserStatus() async {
        let contactIds = contacts.map { $0.id }
        let platformUsers = await checkPlatformUsers(contactIds)

        contacts = contacts.map { contact in
            if let platformUserId = platformUsers[contact.id] {
                return ContactPerson(
                    id: contact.id,
                    fullName: contact.fullName,
                    givenName: contact.givenName,
                    familyName: contact.familyName,
                    birthday: contact.birthday,
                    imageData: contact.imageData,
                    isPlatformUser: true,
                    platformUserId: platformUserId
                )
            }
            return contact
        }
    }
}

// MARK: - Preview Helpers

extension ContactPerson {
    static var mock: ContactPerson {
        ContactPerson(
            id: "mock-1",
            fullName: "Sarah Johnson",
            givenName: "Sarah",
            familyName: "Johnson",
            birthday: DateComponents(year: 1992, month: 7, day: 15),
            imageData: nil,
            isPlatformUser: false,
            platformUserId: nil
        )
    }

    static var mockWithoutBirthday: ContactPerson {
        ContactPerson(
            id: "mock-2",
            fullName: "Alex Smith",
            givenName: "Alex",
            familyName: "Smith",
            birthday: nil,
            imageData: nil,
            isPlatformUser: false,
            platformUserId: nil
        )
    }

    static var mockPlatformUser: ContactPerson {
        ContactPerson(
            id: "mock-3",
            fullName: "Maya Chen",
            givenName: "Maya",
            familyName: "Chen",
            birthday: DateComponents(year: 1995, month: 3, day: 22),
            imageData: nil,
            isPlatformUser: true,
            platformUserId: "user-123"
        )
    }
}
