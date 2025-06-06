import SwiftUI
import ChatService
import DataModels
import AuthKit

/// Main chat interface with Claude-powered astrology assistant.
struct ChatView: View {
    @StateObject private var chatManager: ChatManager
    @State private var selectedConversation: ChatConversation?
    @State private var showingNewChat = false
    
    init(authManager: AuthManager) {
        let apiKey = (try? KeychainHelper.retrieve("astronova.claudeAPIKey")) ?? ""
        self._chatManager = StateObject(wrappedValue: ChatManager(apiKey: apiKey, authManager: authManager))
    }
    
    var body: some View {
        NavigationStack {
            conversationsList
                .navigationTitle("Astrology Chat")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        newChatButton
                    }
                }
        }
        .sheet(isPresented: $showingNewChat) {
            NewChatView(chatManager: chatManager) { conversation in
                selectedConversation = conversation
                showingNewChat = false
            }
        }
        .task {
            await chatManager.chatRepository.fetchConversations()
        }
    }
    
    private var conversationsList: some View {
        Group {
            if chatManager.chatRepository.conversations.isEmpty {
                emptyState
            } else {
                List(chatManager.chatRepository.conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .onTapGesture {
                            selectedConversation = conversation
                        }
                }
            }
        }
        .navigationDestination(item: $selectedConversation) { conversation in
            ChatConversationView(conversation: conversation, chatManager: chatManager)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Start Your Astrological Journey")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ask questions about your birth chart, get insights on current transits, or explore your astrological profile.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Start New Chat") {
                showingNewChat = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var newChatButton: some View {
        Button {
            showingNewChat = true
        } label: {
            Image(systemName: "plus")
        }
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Text(RelativeDateTimeFormatter().localizedString(for: conversation.lastActivity, relativeTo: Date()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(conversation.messageCount) messages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    ChatView(authManager: AuthManager())
}
#endif
