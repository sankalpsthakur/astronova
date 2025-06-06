import Foundation
import CloudKit
import CloudKitKit
import DataModels
import Combine

/// Repository for managing chat conversations and messages in CloudKit.
public final class ChatRepository: ObservableObject {
    
    @Published public private(set) var conversations: [ChatConversation] = []
    @Published public private(set) var currentMessages: [ChatMessage] = []
    @Published public private(set) var isLoading = false
    
    private let database = CKContainer.cosmic.privateCloudDatabase
    
    public init() {}
    
    // MARK: - Conversations
    
    /// Fetches all conversations for the current user.
    @MainActor
    public func fetchConversations() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let query = CKQuery(recordType: ChatConversation.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastActivity", ascending: false)]
        
        let records = try await database.records(matching: query).matchResults.compactMap { result in
            try? result.1.get()
        }
        
        conversations = try records.map { try ChatConversation(record: $0) }
    }
    
    /// Creates a new conversation.
    @MainActor
    public func createConversation(title: String) async throws -> ChatConversation {
        let conversation = ChatConversation(title: title)
        let record = conversation.toRecord(in: nil)
        
        _ = try await database.save(record)
        
        conversations.insert(conversation, at: 0)
        return conversation
    }
    
    /// Updates an existing conversation.
    @MainActor
    public func updateConversation(_ conversation: ChatConversation) async throws {
        let record = conversation.toRecord(in: nil)
        _ = try await database.modifyRecords(saving: [record], deleting: [])
        
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }
    }
    
    /// Deletes a conversation and all its messages.
    @MainActor
    public func deleteConversation(_ conversation: ChatConversation) async throws {
        // Delete all messages in the conversation first
        try await deleteMessagesForConversation(conversation.id)
        
        // Delete the conversation record
        let recordID = CKRecord.ID(recordName: conversation.id)
        _ = try await database.deleteRecord(withID: recordID)
        
        conversations.removeAll { $0.id == conversation.id }
    }
    
    // MARK: - Messages
    
    /// Fetches messages for a specific conversation.
    @MainActor
    public func fetchMessages(for conversationID: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let predicate = NSPredicate(format: "conversationID == %@", conversationID)
        let query = CKQuery(recordType: ChatMessage.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let records = try await database.records(matching: query).matchResults.compactMap { result in
            try? result.1.get()
        }
        
        currentMessages = try records.map { try ChatMessage(record: $0) }
    }
    
    /// Adds a new message to a conversation.
    @MainActor
    public func addMessage(_ message: ChatMessage) async throws {
        let record = message.toRecord(in: nil)
        _ = try await database.save(record)
        
        currentMessages.append(message)
        
        // Update conversation's last activity and message count
        if let conversation = conversations.first(where: { $0.id == message.conversationID }) {
            let updatedConversation = ChatConversation(
                id: conversation.id,
                title: conversation.title,
                lastActivity: message.timestamp,
                messageCount: conversation.messageCount + 1
            )
            try await updateConversation(updatedConversation)
        }
    }
    
    /// Adds multiple messages in batch (useful for conversations with user + assistant messages).
    @MainActor
    public func addMessages(_ messages: [ChatMessage]) async throws {
        let records = messages.map { $0.toRecord(in: nil) }
        _ = try await database.modifyRecords(saving: records, deleting: [])
        
        currentMessages.append(contentsOf: messages)
        
        // Update conversation with the latest message timestamp
        if let lastMessage = messages.last,
           let conversation = conversations.first(where: { $0.id == lastMessage.conversationID }) {
            let updatedConversation = ChatConversation(
                id: conversation.id,
                title: conversation.title,
                lastActivity: lastMessage.timestamp,
                messageCount: conversation.messageCount + messages.count
            )
            try await updateConversation(updatedConversation)
        }
    }
    
    // MARK: - Private Methods
    
    private func deleteMessagesForConversation(_ conversationID: String) async throws {
        let predicate = NSPredicate(format: "conversationID == %@", conversationID)
        let query = CKQuery(recordType: ChatMessage.recordType, predicate: predicate)
        
        let records = try await database.records(matching: query).matchResults.compactMap { result in
            try? result.1.get()
        }
        
        let recordIDs = records.map { $0.recordID }
        if !recordIDs.isEmpty {
            _ = try await database.modifyRecords(saving: [], deleting: recordIDs)
        }
    }
}

