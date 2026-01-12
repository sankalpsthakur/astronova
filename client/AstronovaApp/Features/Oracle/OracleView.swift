import SwiftUI

// MARK: - Oracle View
// The cosmic oracle consultation surface

struct OracleView: View {
    @StateObject private var viewModel = OracleViewModel(quotaManager: OracleQuotaManager.shared)
    @EnvironmentObject private var auth: AuthState
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.cosmicVoid
                    .ignoresSafeArea()

                if auth.isAuthenticated {
                    VStack(spacing: 0) {
                        // Limit banner (when quota exhausted)
                        if viewModel.quotaManager.isLimited {
                            OracleQuotaBanner(
                                resetCountdown: viewModel.quotaManager.resetCountdown,
                                onBuyCredits: { viewModel.showingCreditPacks = true },
                                onUpgrade: { viewModel.showingPaywall = true }
                            )
                        }

                        // Messages
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: Cosmic.Spacing.md) {
                                    ForEach(viewModel.messages) { message in
                                        OracleInsightCard(message: message)
                                            .id(message.id)
                                    }

                                    // Typing indicator
                                    if viewModel.isLoading {
                                        OracleTypingIndicator()
                                    }

                                    // Error
                                    if let error = viewModel.errorMessage {
                                        OracleErrorBanner(message: error) {
                                            viewModel.dismissError()
                                        }
                                    }
                                }
                                .padding(.horizontal, Cosmic.Spacing.screen)
                                .padding(.top, Cosmic.Spacing.md)
                                .padding(.bottom, Cosmic.Spacing.xl)
                            }
                            .accessibilityLabel(L10n.Oracle.Accessibility.conversationLabel)
                            .accessibilityHint(L10n.Oracle.Accessibility.conversationHint)
                            .accessibilityElement(children: .contain)
                            .onChange(of: viewModel.messages.count) { _, _ in
                                if let lastId = viewModel.messages.last?.id {
                                    withAnimation {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }

                        Spacer(minLength: 0)

                        // Input area
                        OracleInputArea(
                            text: $viewModel.inputText,
                            depth: $viewModel.selectedDepth,
                            prompts: viewModel.contextualPrompts,
                            isDisabled: viewModel.isLoading || viewModel.quotaManager.isLimited,
                            onSend: { viewModel.sendMessage() },
                            onPromptTap: { viewModel.selectPrompt($0) }
                        )
                        .padding(.bottom, 100) // Tab bar clearance
                    }
                } else {
                    VStack {
                        Spacer()
                        AuthRequiredView(
                            title: L10n.Oracle.signInRequired,
                            message: L10n.Oracle.signInMessage
                        )
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    OracleNavTitle()
                }
            }
        }
        .onAppear {
            viewModel.quotaManager.refresh()
            // Check if we should show chat packages (triggered from PaywallView)
            if triggerShowChatPackages {
                triggerShowChatPackages = false
                viewModel.showingCreditPacks = true
            }
        }
        .onChange(of: triggerShowChatPackages) { _, newValue in
            if newValue {
                triggerShowChatPackages = false
                viewModel.showingCreditPacks = true
            }
        }
        .sheet(isPresented: $viewModel.showingPaywall) {
            PaywallView(context: .chatLimit)
        }
        .sheet(isPresented: $viewModel.showingCreditPacks) {
            ChatPackagesSheet()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// ... rest of file unchanged ...
