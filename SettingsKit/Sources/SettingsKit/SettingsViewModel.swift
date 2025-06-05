import Foundation
import Combine
import CloudKitKit
import CloudKit

/// ViewModel for managing user settings persisted in CloudKit and UserDefaults.
@available(iOS 13.0, *)
public final class SettingsViewModel: ObservableObject {
    @Published public var selectedLanguage: String
    @Published public var notificationPrefs: NotificationPrefs

    private let database: CKDatabaseProxy
    private let defaults: UserDefaults

    private static let kLangKey  = "settings.language"
    private static let kNotifKey = "settings.notification"

    public init(defaultLanguage: String = Locale.current.identifier,
                database: CKDatabaseProxy = .private,
                defaults: UserDefaults = .standard) {
        self.database = database
        self.defaults = defaults
        self.selectedLanguage = defaultLanguage
        self.notificationPrefs = NotificationPrefs()
        loadFromDefaults()
        Task { await loadFromCloud() }
    }

    private func loadFromDefaults() {
        if let lang = defaults.string(forKey: Self.kLangKey) {
            selectedLanguage = lang
        }
        if let data = defaults.data(forKey: Self.kNotifKey),
           let prefs = try? JSONDecoder().decode(NotificationPrefs.self, from: data) {
            notificationPrefs = prefs
        }
    }

    private func saveToDefaults() {
        defaults.set(selectedLanguage, forKey: Self.kLangKey)
        if let data = try? JSONEncoder().encode(notificationPrefs) {
            defaults.set(data, forKey: Self.kNotifKey)
        }
    }

    @MainActor
    public func loadFromCloud() async {
        do {
            let langID = CKRecord.ID(recordName: "language", zoneID: CKRecordZone.default().zoneID)
            let record = try await database.fetchRecord(id: langID)
            if let lang = record["identifier"] as? String {
                selectedLanguage = lang
            }
        } catch { }

        do {
            let notifID = CKRecord.ID(recordName: "prefs", zoneID: CKRecordZone.default().zoneID)
            let prefs: NotificationPrefs = try await database.fetch(type: NotificationPrefs.self, id: notifID)
            notificationPrefs = prefs
        } catch { }

        saveToDefaults()
    }

    @MainActor
    public func saveToCloud() async {
        saveToDefaults()

        do {
            let langID = CKRecord.ID(recordName: "language", zoneID: CKRecordZone.default().zoneID)
            let record: CKRecord
            do {
                record = try await database.fetchRecord(id: langID)
            } catch {
                record = CKRecord(recordType: "LanguagePrefs", recordID: langID)
            }
            record["identifier"] = selectedLanguage as CKRecordValue
            _ = try await database.saveRecord(record)
        } catch {
            print("[SettingsViewModel] failed to save language: \(error)")
        }

        do {
            _ = try await database.save(notificationPrefs, zone: CKRecordZone.default().zoneID)
        } catch {
            print("[SettingsViewModel] failed to save notification prefs: \(error)")
        }
    }
}