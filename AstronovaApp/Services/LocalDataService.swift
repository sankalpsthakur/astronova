import Foundation
import CoreData

/// Handles offline content snapshots using Core Data
class LocalDataService {
    static let shared = LocalDataService()

    private let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "OfflineContent", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Failed to load persistent store: \(error)")
            }
        }
    }

    // MARK: - Managed Object Model
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let horoscopeEntity = NSEntityDescription()
        horoscopeEntity.name = "CachedHoroscope"
        horoscopeEntity.managedObjectClassName = "NSManagedObject"
        horoscopeEntity.properties = [
            stringAttr("id"),
            stringAttr("sign"),
            dateAttr("date"),
            stringAttr("content")
        ]

        let chatEntity = NSEntityDescription()
        chatEntity.name = "CachedChatMessage"
        chatEntity.managedObjectClassName = "NSManagedObject"
        chatEntity.properties = [
            stringAttr("id"),
            stringAttr("role"),
            stringAttr("content"),
            dateAttr("timestamp")
        ]

        model.entities = [horoscopeEntity, chatEntity]
        return model
    }

    private static func stringAttr(_ name: String) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = .stringAttributeType
        attr.isOptional = false
        return attr
    }

    private static func dateAttr(_ name: String) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = .dateAttributeType
        attr.isOptional = false
        return attr
    }

    // MARK: - Save helpers
    private func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func saveHoroscopes(_ horoscopes: [HoroscopeResponse]) throws {
        let context = container.newBackgroundContext()
        try context.performAndWait {
            for h in horoscopes {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "CachedHoroscope", into: context)
                obj.setValue("\(h.sign)-\(h.date.timeIntervalSince1970)", forKey: "id")
                obj.setValue(h.sign, forKey: "sign")
                obj.setValue(h.date, forKey: "date")
                obj.setValue(h.content, forKey: "content")
            }
            try saveContext(context)
        }
    }

    func saveChatMessages(_ messages: [ChatMessage]) throws {
        let context = container.newBackgroundContext()
        try context.performAndWait {
            for m in messages {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "CachedChatMessage", into: context)
                obj.setValue(m.id, forKey: "id")
                obj.setValue("user", forKey: "role")
                obj.setValue(m.response, forKey: "content")
                if let date = ISO8601DateFormatter().date(from: m.timestamp) {
                    obj.setValue(date, forKey: "timestamp")
                }
            }
            try saveContext(context)
        }
    }

    func fetchHoroscope(sign: String, date: Date) -> HoroscopeResponse? {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedHoroscope")
        request.predicate = NSPredicate(format: "sign == %@ AND date == %@", sign, date as NSDate)
        request.fetchLimit = 1
        guard let result = try? context.fetch(request).first,
              let content = result.value(forKey: "content") as? String else {
            return nil
        }
        return HoroscopeResponse(sign: sign, period: "daily", content: content, date: date)
    }

    func fetchRecentChats(limit: Int = 10) -> [ChatMessage] {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedChatMessage")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { obj in
            guard let id = obj.value(forKey: "id") as? String,
                  let content = obj.value(forKey: "content") as? String,
                  let timestamp = obj.value(forKey: "timestamp") as? Date else { return nil }
            return ChatMessage(id: id, message: "", response: content, timestamp: ISO8601DateFormatter().string(from: timestamp), userId: nil)
        }
    }

    // MARK: - Snapshot nightly content
    func snapshotDailyContent() async {
        let profileManager = UserProfileManager()
        guard let sign = profileManager.profile.sunSign else { return }
        do {
            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
            let todayH = try await APIServices.shared.getDailyHoroscope(for: sign, date: today)
            let tomorrowH = try await APIServices.shared.getDailyHoroscope(for: sign, date: tomorrow)
            try saveHoroscopes([todayH, tomorrowH])
            let history = try await APIServices.shared.getChatHistory()
            let lastTen = Array(history.suffix(10))
            try saveChatMessages(lastTen)
        } catch {
            print("Snapshot failed: \(error)")
        }
    }
}

