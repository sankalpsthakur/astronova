import Foundation
import CloudKit
import CloudKitKit

/// Manages app language selection and localization.
public final class LanguageManager {
    private let defaults: UserDefaults
    private let database: CKDatabaseProxy

    private static let kLangKey = "settings.language"

    public init(database: CKDatabaseProxy = .private,
                defaults: UserDefaults = .standard) {
        self.database = database
        self.defaults = defaults
    }

    /// Loads the preferred language from defaults and CloudKit.
    public func loadLanguage(default defaultLang: String = Locale.current.identifier) async -> String {
        var lang = defaults.string(forKey: Self.kLangKey) ?? defaultLang

        do {
            let id = CKRecord.ID(recordName: "language", zoneID: CKRecordZone.default().zoneID)
            let record = try await database.fetchRecord(id: id)
            if let cloud = record["identifier"] as? String {
                lang = cloud
                defaults.set(cloud, forKey: Self.kLangKey)
            }
        } catch { }

        return lang
    }

    /// Persists the language to defaults and CloudKit.
    public func saveLanguage(_ identifier: String) async {
        defaults.set(identifier, forKey: Self.kLangKey)

        do {
            let id = CKRecord.ID(recordName: "language", zoneID: CKRecordZone.default().zoneID)
            let record: CKRecord
            do {
                record = try await database.fetchRecord(id: id)
            } catch {
                record = CKRecord(recordType: "LanguagePrefs", recordID: id)
            }
            record["identifier"] = identifier as CKRecordValue
            _ = try await database.saveRecord(record)
        } catch { }
    }
}