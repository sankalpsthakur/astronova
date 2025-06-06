import SwiftUI
import ChatService
import DataModels

/// View for starting a new chat conversation with suggested questions.
struct NewChatView: View {
    let chatManager: ChatManager
    let onConversationCreated: (ChatConversation) -> Void
    
    @State private var messageText = ""
    @State private var isCreating = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                suggestedQuestionsSection
                messageInputSection
                Spacer()
            }
            .padding()
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
        }
        .task {
            await chatManager.loadSuggestedQuestions()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
            
            Text("Ask Your Astrology Question")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Get personalized insights from our AI astrologer about your birth chart, transits, and more.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Questions")
                .font(.headline)
                .padding(.horizontal)
            
            if chatManager.suggestedQuestions.isEmpty {
                // Fallback questions while loading
                VStack(spacing: 8) {
                    ForEach(fallbackQuestions, id: \.self) { question in
                        SuggestedQuestionButton(question: question) {
                            messageText = question
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(chatManager.suggestedQuestions, id: \.self) { question in
                        SuggestedQuestionButton(question: question) {
                            messageText = question
                        }
                    }
                }
            }
        }
    }
    
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Or ask your own question:")
                .font(.headline)
            
            TextField("Type your astrology question here...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    private var fallbackQuestions: [String] {
        [
            "What does my birth chart say about my personality?",
            "How do current planetary transits affect me?",
            "What career paths align with my astrological profile?"
        ]
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty && !isCreating else { return }
        
        isCreating = true
        
        Task {
            if let conversation = await chatManager.startNewConversation(with: trimmedMessage) {
                await MainActor.run {
                    onConversationCreated(conversation)
                }
            }
            await MainActor.run {
                isCreating = false
            }
        }
    }
}

struct SuggestedQuestionButton: View {
    let question: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(question)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NewChatView(
        chatManager: ChatManager(apiKey: "test", authManager: AuthManager()),
        onConversationCreated: { _ in }
    )
}
#endif