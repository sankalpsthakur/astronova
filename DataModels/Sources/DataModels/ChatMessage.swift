import Foundation
import CloudKit

/// Represents a single message in the astrology chat conversation.
public struct ChatMessage: CKRecordConvertible, Codable, Identifiable {
    /// The CloudKit record type for ChatMessage.
    public static let recordType = "ChatMessage"
    
    public let id: String
    public let content: String
    public let role: MessageRole
    public let timestamp: Date
    public let conversationID: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum MessageRole: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
    
    public init(
        id: String = UUID().uuidString,
        content: String,
        role: MessageRole,
        timestamp: Date = Date(),
        conversationID: String
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.conversationID = conversationID
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(record: CKRecord) throws {
        guard let content = record["content"] as? String,
              let roleString = record["role"] as? String,
              let role = MessageRole(rawValue: roleString),
              let timestamp = record["timestamp"] as? Date,
              let conversationID = record["conversationID"] as? String else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required ChatMessage fields"])
        }
        
        self.id = record.recordID.recordName
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.conversationID = conversationID
        self.createdAt = record.creationDate ?? Date()
        self.updatedAt = record.modificationDate ?? Date()
    }
    
    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: ChatMessage.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: ChatMessage.recordType)
        }
        
        record["content"] = content as CKRecordValue
        record["role"] = role.rawValue as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
        record["conversationID"] = conversationID as CKRecordValue
        
        return record
    }
}

/// Represents a conversation thread in the astrology chat.
public struct ChatConversation: CKRecordConvertible, Codable, Identifiable {
    /// The CloudKit record type for ChatConversation.
    public static let recordType = "ChatConversation"
    
    public let id: String
    public let title: String
    public let lastActivity: Date
    public let messageCount: Int
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        lastActivity: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.lastActivity = lastActivity
        self.messageCount = messageCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(record: CKRecord) throws {
        guard let title = record["title"] as? String,
              let lastActivity = record["lastActivity"] as? Date,
              let messageCount = record["messageCount"] as? Int else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required ChatConversation fields"])
        }
        
        self.id = record.recordID.recordName
        self.title = title
        self.lastActivity = lastActivity
        self.messageCount = messageCount
        self.createdAt = record.creationDate ?? Date()
        self.updatedAt = record.modificationDate ?? Date()
    }
    
    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: ChatConversation.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: ChatConversation.recordType)
        }
        
        record["title"] = title as CKRecordValue
        record["lastActivity"] = lastActivity as CKRecordValue
        record["messageCount"] = messageCount as CKRecordValue
        
        return record
    }
}