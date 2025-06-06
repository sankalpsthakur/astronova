import XCTest
@testable import ChatService
import DataModels

final class ChatServiceTests: XCTestCase {
    
    func testChatMessageCreation() throws {
        let message = ChatMessage(
            content: "What's my sun sign?",
            role: .user,
            conversationID: "test-conversation"
        )
        
        XCTAssertEqual(message.content, "What's my sun sign?")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.conversationID, "test-conversation")
        XCTAssertFalse(message.id.isEmpty)
    }
    
    func testChatConversationCreation() throws {
        let conversation = ChatConversation(
            title: "Test Conversation",
            messageCount: 5
        )
        
        XCTAssertEqual(conversation.title, "Test Conversation")
        XCTAssertEqual(conversation.messageCount, 5)
        XCTAssertFalse(conversation.id.isEmpty)
    }
    
    func testClaudeServiceInit() throws {
        let service = ClaudeAPIService(apiKey: "test-key")
        XCTAssertNotNil(service)
    }
}