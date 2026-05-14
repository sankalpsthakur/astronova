import SwiftUI

// MARK: - Oracle View
// The cosmic oracle consultation surface

struct OracleView: View {
    @StateObject private var viewModel = OracleViewModel(quotaManager: OracleQuotaManager.shared)
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false

    // Wave 11 polish — Move 1: Oracle paywall preamble. When the trigger fires
    // (3rd Oracle action), this arm goes true. We wait for the *next* AI reply
    // to actually land — `isLoading` flipping true→false — before showing the
    // "Shastriji wants to say more" line. That way the preamble doesn't race
    // the loading state.
    @State private var oracleMoreLineArmed: Bool = false
    @State private var oracleMoreLineVisible: Bool = false

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
                                            .id("typing")
                                    }

                                    // Error
                                    if let error = viewModel.errorMessage {
                                        OracleErrorBanner(message: error) {
                                            viewModel.dismissError()
                                        }
                                        .id("error")
                                    }

                                    // Wave 11 polish — Move 1: "Shastriji wants to say more"
                                    // preamble. Visible only after the 3rd-session trigger
                                    // and after the reply that followed has landed.
                                    if oracleMoreLineVisible {
                                        PaywallOracleMoreLine {
                                            oracleMoreLineVisible = false
                                            PaywallTrigger.afterOracleSession3.firePaywallNow()
                                        }
                                        .id("oraclePreambleMore")
                                        .transition(.opacity)
                                    }
                                }
                                .padding(.horizontal, Cosmic.Spacing.screen)
                                .padding(.top, Cosmic.Spacing.md)
                                .padding(.bottom, 120) // Space for input area + safe area
                            }
                            .accessibilityLabel(L10n.Oracle.Accessibility.conversationLabel)
                            .accessibilityHint(L10n.Oracle.Accessibility.conversationHint)
                            .accessibilityElement(children: .contain)
                            .onChange(of: viewModel.messages.count) { _, _ in
                                scrollToBottom(proxy: proxy)
                            }
                            .onChange(of: viewModel.isLoading) { _, newValue in
                                if newValue {
                                    withAnimation {
                                        proxy.scrollTo("typing", anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: viewModel.errorMessage) { _, newValue in
                                if newValue != nil {
                                    withAnimation {
                                        proxy.scrollTo("error", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }

                        // Input area (pinned to bottom)
                        OracleInputArea(
                            text: $viewModel.inputText,
                            depth: $viewModel.selectedDepth,
                            prompts: viewModel.contextualPrompts,
                            isDisabled: viewModel.isLoading || viewModel.quotaManager.isLimited,
                            onSend: {
                                let before = viewModel.messages.count
                                viewModel.sendMessage()
                                if viewModel.messages.count > before {
                                    gamification.markOracleAction()
                                }
                            },
                            onPromptTap: { viewModel.selectPrompt($0) }
                        )
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
        .overlay {
            if viewModel.isPreparingCeremony {
                ShastrijiOpeningCeremony()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isPreparingCeremony)
        // Wave 11 polish — Move 1: arm the Oracle paywall preamble on the
        // 3rd-session trigger. The line itself waits for the next AI reply.
        .onReceive(NotificationCenter.default.publisher(for: .paywallPreambleRequested)) { note in
            guard let event = PaywallPreambleEvent(note),
                  event.trigger == .afterOracleSession3,
                  !TestEnvironment.shared.isUITest else { return }
            oracleMoreLineArmed = true
        }
        // Reply lands when isLoading goes true→false. Reveal the line then.
        .onChange(of: viewModel.isLoading) { wasLoading, isLoading in
            guard wasLoading, !isLoading, oracleMoreLineArmed else { return }
            oracleMoreLineArmed = false
            withAnimation(.easeIn(duration: 0.45)) {
                oracleMoreLineVisible = true
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isLoading {
            withAnimation {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if viewModel.errorMessage != nil {
            withAnimation {
                proxy.scrollTo("error", anchor: .bottom)
            }
        } else if let lastId = viewModel.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Shastriji Opening Ceremony

/// 2-second elegant overlay shown when a new Oracle session begins.
/// Pure typography + a slow-pulsing sigil — no heavy assets, no haptics.
private struct ShastrijiOpeningCeremony: View {
    @State private var pulse: Bool = false
    @State private var dotPhase: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.cosmicVoid
                .opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: Cosmic.Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.cosmicGold.opacity(0.25), lineWidth: 1)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.15 : 0.95)
                        .opacity(pulse ? 0.0 : 0.8)
                    Image(systemName: "sparkle")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.cosmicGold)
                        .scaleEffect(pulse ? 1.05 : 1.0)
                }
                .frame(height: 110)
                .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text("Shastriji")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .tracking(2.0)
                        .textCase(.uppercase)
                    Text("is preparing your reading\(dots)")
                        .font(.cosmicBody.italic())
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .accessibilityLabel("Shastriji is preparing your reading")
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            // Animate the trailing dots while the ceremony plays (~2s).
            Task { @MainActor in
                for i in 1...6 {
                    try? await Task.sleep(nanoseconds: 330_000_000)
                    dotPhase = i % 4
                }
            }
        }
    }

    private var dots: String {
        switch dotPhase {
        case 1: return "."
        case 2: return ".."
        case 3: return "..."
        default: return ""
        }
    }
}
