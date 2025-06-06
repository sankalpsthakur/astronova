import SwiftUI
import ChatService
import ChartVisualization
import DataModels

/// Enhanced chat conversation view with chart integration and premium features.
struct EnhancedChatConversationView: View {
    let conversation: ChatConversation
    let chatManager: EnhancedChatManager
    
    @State private var messageText = ""
    @State private var showingPaywall = false
    @State private var showingChartSheet = false
    @State private var remainingFreeMessages = 0
    @State private var isPremium = false
    
    var body: some View {
        VStack(spacing: 0) {
            messagesList
            chartQuickActions
            messageInputArea
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                chartMenuButton
            }
        }
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $showingPaywall) {
            ChartPremiumPaywallView()
        }
        .sheet(isPresented: $showingChartSheet) {
            if let chart = chatManager.currentChart {
                NavigationView {
                    ChartView(
                        chart: chart,
                        transitPlanets: chatManager.charts.transitPlanets,
                        isPremium: isPremium
                    )
                    .navigationTitle("Birth Chart")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingChartSheet = false
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: chatManager.showingChart) { showing in
            if showing {
                showingChartSheet = true
                chatManager.showingChart = false
            }
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatManager.chatRepository.currentMessages) { message in
                        EnhancedMessageBubble(
                            message: message,
                            chatManager: chatManager,
                            isPremium: isPremium
                        )
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
    
    private var chartQuickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ChartActionButton(
                    title: "Birth Chart",
                    icon: "chart.pie",
                    isPremium: false
                ) {
                    Task {
                        await chatManager.showBirthChart()
                    }
                }
                
                ChartActionButton(
                    title: "Transits",
                    icon: "arrow.triangle.2.circlepath",
                    isPremium: true
                ) {
                    Task {
                        if isPremium {
                            await chatManager.showTransitChart()
                        } else {
                            showingPaywall = true
                        }
                    }
                }
                
                ChartActionButton(
                    title: "Aspects",
                    icon: "line.3.crossed.swirl.circle",
                    isPremium: true
                ) {
                    if isPremium {
                        // Show aspects view
                    } else {
                        showingPaywall = true
                    }
                }
                
                ChartActionButton(
                    title: "Houses",
                    icon: "house.lodge",
                    isPremium: false
                ) {
                    // Show houses explanation
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
    
    private var messageInputArea: some View {
        VStack(spacing: 8) {
            if !isPremium && remainingFreeMessages <= 3 {
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
    
    private var chartMenuButton: some View {
        Menu {
            Button {
                Task { await chatManager.showBirthChart(sidereal: true) }
            } label: {
                Label("Sidereal Birth Chart", systemImage: "chart.pie")
            }
            
            Button {
                Task { await chatManager.showBirthChart(sidereal: false) }
            } label: {
                Label("Tropical Birth Chart", systemImage: "chart.pie")
            }
            
            Divider()
            
            if isPremium {
                Button {
                    Task { await chatManager.showTransitChart(sidereal: true) }
                } label: {
                    Label("Current Transits", systemImage: "arrow.triangle.2.circlepath")
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Current Transits (Premium)", systemImage: "lock")
                }
            }
        } label: {
            Image(systemName: "chart.xyaxis.line")
        }
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
        
        Task {
            let hasPremium = await chatManager.hasPremiumAccess()
            if !hasPremium && remainingFreeMessages <= 0 {
                showingPaywall = true
                return
            }
            
            messageText = ""
            await chatManager.sendMessage(trimmedMessage, in: conversation.id)
            remainingFreeMessages = await chatManager.getRemainingFreeMessages()
        }
    }
    
    private func loadInitialData() async {
        await chatManager.chatRepository.fetchMessages(for: conversation.id)
        isPremium = await chatManager.hasPremiumAccess()
        remainingFreeMessages = await chatManager.getRemainingFreeMessages()
    }
}

// MARK: - Supporting Views

struct EnhancedMessageBubble: View {
    let message: ChatMessage
    let chatManager: EnhancedChatManager
    let isPremium: Bool
    
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    // Chart integration for assistant messages
                    if shouldShowChart(for: message) {
                        chartAttachment
                    }
                    
                    // Premium teasers for non-premium users
                    if shouldShowPremiumTeaser(for: message) && !isPremium {
                        premiumTeaser
                    }
                }
            }
            .padding()
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var chartAttachment: some View {
        Group {
            if let chart = chatManager.currentChart {
                ChatChartView(
                    chart: chart,
                    isPremium: isPremium,
                    showTransits: isPremium
                )
            }
        }
    }
    
    private var premiumTeaser: some View {
        ChartPremiumTeaser(
            feature: "Detailed Chart Analysis",
            description: "Unlock planetary aspects, current transits, and personalized interpretations."
        ) {
            // Handle premium upgrade
        }
    }
    
    private func shouldShowChart(for message: ChatMessage) -> Bool {
        guard message.role == .assistant else { return false }
        
        let chartKeywords = ["chart", "birth chart", "planets", "houses"]
        let content = message.content.lowercased()
        
        return chartKeywords.contains { content.contains($0) } && chatManager.currentChart != nil
    }
    
    private func shouldShowPremiumTeaser(for message: ChatMessage) -> Bool {
        guard message.role == .assistant else { return false }
        
        let premiumKeywords = ["aspects", "transits", "detailed", "deep analysis"]
        let content = message.content.lowercased()
        
        return premiumKeywords.contains { content.contains($0) }
    }
}

struct ChartActionButton: View {
    let title: String
    let icon: String
    let isPremium: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary, in: Capsule())
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

struct ChartPremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                featuresSection
                pricingSection
                Spacer()
            }
            .padding()
            .navigationTitle("Unlock Full Charts")
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
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Premium Astrological Charts")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get detailed birth charts, current transits, planetary aspects, and personalized AI insights.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(
                icon: "chart.pie.fill",
                title: "Complete Birth Charts",
                description: "Sidereal & Tropical charts with all planets and houses"
            )
            
            FeatureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Live Transit Tracking",
                description: "Current planetary positions and their effects on your chart"
            )
            
            FeatureRow(
                icon: "line.3.crossed.swirl.circle",
                title: "Planetary Aspects",
                description: "Detailed aspect analysis showing planetary relationships"
            )
            
            FeatureRow(
                icon: "sparkles",
                title: "AI Chart Interpretation",
                description: "Personalized insights from our advanced AI astrologer"
            )
            
            FeatureRow(
                icon: "message.fill",
                title: "Unlimited Chat",
                description: "Ask unlimited questions about your astrological profile"
            )
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Button("Start Premium - $9.99/month") {
                // Handle premium purchase
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Text("Cancel anytime. 7-day free trial.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        EnhancedChatConversationView(
            conversation: ChatConversation(title: "My Birth Chart Analysis"),
            chatManager: EnhancedChatManager(apiKey: "test", authManager: AuthManager())
        )
    }
}
#endif