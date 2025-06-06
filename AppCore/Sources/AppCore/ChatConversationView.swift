import SwiftUI
import ChatService
import DataModels

/// View for displaying and interacting with a specific chat conversation.
struct ChatConversationView: View {
    let conversation: ChatConversation
    let chatManager: ChatManager
    
    @State private var messageText = ""
    @State private var showingPaywall = false
    @State private var remainingFreeMessages = 0
    
    var body: some View {
        VStack(spacing: 0) {
            messagesList
            messageInputArea
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await chatManager.chatRepository.fetchMessages(for: conversation.id)
            await MainActor.run {
                Task {
                    remainingFreeMessages = await chatManager.getRemainingFreeMessages()
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatManager.chatRepository.currentMessages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if chatManager.isProcessing {
                        TypingIndicator()
                    }
                }
                .padding()
            }
            .onChange(of: chatManager.chatRepository.currentMessages.count) { _ in
                if let lastMessage = chatManager.chatRepository.currentMessages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInputArea: some View {
        VStack(spacing: 8) {
            if remainingFreeMessages <= 3 && remainingFreeMessages > 0 {
                freeMessageWarning
            } else if remainingFreeMessages == 0 {
                freeMessageWarning
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask about your astrology...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(chatManager.isProcessing)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .background(.blue, in: Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isProcessing)
            }
            .padding()
        }
        .background(.regularMaterial)
    }
    
    private var freeMessageWarning: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(.orange)
            
            if remainingFreeMessages > 0 {
                Text("\(remainingFreeMessages) free messages remaining today")
            } else {
                Text("Daily free messages used. Upgrade for unlimited chat.")
            }
            
            Spacer()
            
            if remainingFreeMessages == 0 {
                Button("Upgrade") {
                    showingPaywall = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty && !chatManager.isProcessing else { return }
        
        // Check if user has reached free message limit
        Task {
            let hasPremium = await chatManager.hasPremiumAccess()
            if !hasPremium && remainingFreeMessages <= 0 {
                showingPaywall = true
                return
            }
            
            await chatManager.sendMessage(trimmedMessage, in: conversation.id)
            remainingFreeMessages = await chatManager.getRemainingFreeMessages()
        }
        
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                userMessageBubble
            } else {
                assistantMessageBubble
                Spacer()
            }
        }
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(.white)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var assistantMessageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .padding(.top, 2)
                
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .padding(.top, 2)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(.gray)
                            .opacity(animationPhase == index ? 1 : 0.3)
                    }
                }
            }
            .padding()
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.6)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                
                Text("Upgrade to Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Get unlimited access to our AI astrologer and unlock premium features.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "message", text: "Unlimited chat messages")
                    FeatureRow(icon: "chart.bar", text: "Advanced birth chart analysis")
                    FeatureRow(icon: "clock", text: "Real-time transit updates")
                    FeatureRow(icon: "heart", text: "Relationship compatibility insights")
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Button("Upgrade Now") {
                    // Handle upgrade purchase
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Later") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    ChatConversationView(
        conversation: ChatConversation(title: "Sample Conversation"),
        chatManager: ChatManager(apiKey: "test", authManager: AuthManager())
    )
}
#endif