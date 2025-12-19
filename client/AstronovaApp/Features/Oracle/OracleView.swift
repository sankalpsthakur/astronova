import SwiftUI

// MARK: - Oracle View
// The cosmic oracle consultation surface

struct OracleView: View {
    @StateObject private var viewModel = OracleViewModel()
    @EnvironmentObject private var auth: AuthState

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.cosmicVoid
                    .ignoresSafeArea()

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

// MARK: - Oracle Nav Title

private struct OracleNavTitle: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(Color.cosmicGold)
            Text("Oracle")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }
}

// MARK: - Oracle Insight Card

private struct OracleInsightCard: View {
    let message: OracleMessage

    var body: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
            if !message.isUser {
                // Oracle avatar
                ZStack {
                    Circle()
                        .fill(Color.cosmicGold.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: message.type.icon)
                        .font(.caption)
                        .foregroundStyle(Color.cosmicGold)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: Cosmic.Spacing.xs) {
                Text(message.text)
                    .font(.cosmicBody)
                    .foregroundStyle(message.isUser ? Color.cosmicTextSecondary : Color.cosmicTextPrimary)
                    .multilineTextAlignment(message.isUser ? .trailing : .leading)

                Text(message.timestamp, style: .time)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(Cosmic.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(message.isUser ? Color.cosmicAmethyst.opacity(0.15) : Color.cosmicSurface)
            )

            if message.isUser {
                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - Oracle Input Area

struct OracleInputArea: View {
    @Binding var text: String
    @Binding var depth: OracleDepth
    let prompts: [String]
    let isDisabled: Bool
    let onSend: () -> Void
    let onPromptTap: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            // Prompt chips (when input is empty)
            if text.isEmpty && !isFocused {
                PromptChipsRow(prompts: prompts, onTap: onPromptTap)
            }

            // Input row
            HStack(spacing: Cosmic.Spacing.sm) {
                // Depth toggle
                DepthToggle(depth: $depth)

                // Text field
                TextField("Ask the Oracle...", text: $text)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .tint(Color.cosmicGold)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.sm + 4)
                    .frame(minHeight: 44)
                    .background(Color.cosmicSurface, in: Capsule())
                    .contentShape(Capsule())
                    .disabled(isDisabled)
                    .onTapGesture {
                        isFocused = true
                    }
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.isEmpty && !isDisabled {
                            onSend()
                        }
                    }

                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            text.isEmpty || isDisabled
                                ? Color.cosmicTextTertiary
                                : Color.cosmicGold
                        )
                }
                .disabled(text.isEmpty || isDisabled)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
        }
        .padding(.vertical, Cosmic.Spacing.sm)
        .background(
            Color.cosmicVoid
                .overlay(
                    LinearGradient(
                        colors: [Color.cosmicVoid.opacity(0), Color.cosmicVoid],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20),
                    alignment: .top
                )
        )
    }
}

// MARK: - Depth Toggle

struct DepthToggle: View {
    @Binding var depth: OracleDepth

    var body: some View {
        Menu {
            ForEach(OracleDepth.allCases, id: \.self) { option in
                Button {
                    depth = option
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text(option.rawValue)
                            Text(option.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: option.icon)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: depth.icon)
                    .font(.caption)
                Text(depth.rawValue)
                    .font(.cosmicCaption)
            }
            .foregroundStyle(Color.cosmicGold)
            .padding(.horizontal, Cosmic.Spacing.sm)
            .padding(.vertical, Cosmic.Spacing.xs)
            .background(Color.cosmicGold.opacity(0.15), in: Capsule())
        }
    }
}

// MARK: - Prompt Chips Row

struct PromptChipsRow: View {
    let prompts: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Cosmic.Spacing.xs) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onTap(prompt)
                    } label: {
                        Text(prompt)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .padding(.horizontal, Cosmic.Spacing.sm)
                            .padding(.vertical, Cosmic.Spacing.xs)
                            .background(Color.cosmicSurface, in: Capsule())
                    }
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
        }
    }
}

// MARK: - Oracle Quota Banner

struct OracleQuotaBanner: View {
    let resetCountdown: String
    let onBuyCredits: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            HStack(spacing: Cosmic.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.cosmicGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily reading complete")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("New insight in \(resetCountdown)")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()
            }

            HStack(spacing: Cosmic.Spacing.sm) {
                Button(action: onBuyCredits) {
                    Text("Get Credits")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Cosmic.Spacing.sm)
                        .background(Color.cosmicGold.opacity(0.15), in: Capsule())
                }

                Button(action: onUpgrade) {
                    Text("Unlock All")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Cosmic.Spacing.sm)
                        .background(Color.cosmicGold, in: Capsule())
                }
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(Color.cosmicGold.opacity(0.1))
    }
}

// MARK: - Oracle Typing Indicator

struct OracleTypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.cosmicGold.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.cosmicGold)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.cosmicGold.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(Cosmic.Spacing.md)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Oracle Error Banner

struct OracleErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.cosmicWarning)

            Text(message)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)

            Spacer()

            Button("Dismiss", action: onDismiss)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicGold)
        }
        .padding(Cosmic.Spacing.md)
        .background(Color.cosmicWarning.opacity(0.1), in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
    }
}

// MARK: - Preview

#Preview("Oracle") {
    OracleView()
        .environmentObject(AuthState())
}
