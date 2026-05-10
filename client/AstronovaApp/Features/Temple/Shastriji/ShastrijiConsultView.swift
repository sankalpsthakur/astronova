//
//  ShastrijiConsultView.swift
//  AstronovaApp
//
//  Shastriji single-practitioner booking and call flow.
//  Three states: Profile+Book, In Queue, Call Ready/In Call.
//

import SwiftUI

// MARK: - View State

private enum ShastrijiViewState: Equatable {
    case profile
    case inQueue(bookingId: String, position: Int, waitMinutes: Int)
    case callReady(bookingId: String)
    case inCall(bookingId: String)

    static func == (lhs: ShastrijiViewState, rhs: ShastrijiViewState) -> Bool {
        switch (lhs, rhs) {
        case (.profile, .profile):
            return true
        case let (.inQueue(lId, lPos, lWait), .inQueue(rId, rPos, rWait)):
            return lId == rId && lPos == rPos && lWait == rWait
        case let (.callReady(lId), .callReady(rId)):
            return lId == rId
        case let (.inCall(lId), .inCall(rId)):
            return lId == rId
        default:
            return false
        }
    }
}

// MARK: - ShastrijiConsultView

struct ShastrijiConsultView: View {
    @EnvironmentObject private var gamification: GamificationManager
    @State private var viewState: ShastrijiViewState = .profile
    @State private var status: ShastrijiStatus?
    @State private var isLoading = true
    @State private var isBooking = false
    @State private var errorMessage: String?
    @State private var callDurationSeconds: Int = 0
    @State private var queueTimer: Timer?
    @State private var callTimer: Timer?
    @State private var pulseAnimation = false
    @State private var showCallView = false
    @State private var sessionURL: String?

    var body: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            switch viewState {
            case .profile:
                profileView
            case let .inQueue(_, position, waitMinutes):
                queueView(position: position, waitMinutes: waitMinutes)
            case .callReady:
                callReadyView
            case .inCall:
                inCallView
            }
        }
        .padding(.vertical, Cosmic.Spacing.md)
        .padding(.horizontal, Cosmic.Spacing.screen)
        .background {
            RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous)
                .fill(Color.cosmicSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cosmicGold.opacity(0.4), Color.cosmicAmethyst.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: Cosmic.Border.medium
                        )
                }
        }
        .cosmicElevation(.medium)
        .padding(.horizontal, Cosmic.Spacing.screen)
        .task {
            await loadStatus()
        }
        .fullScreenCover(isPresented: $showCallView) {
            if let url = sessionURL, case let .inCall(bookingId) = viewState {
                ShastrijiCallView(
                    sessionURL: url,
                    bookingId: bookingId,
                    onEndCall: {
                        showCallView = false
                        Task {
                            _ = try? await APIServices.shared.updateCallState(bookingId: bookingId, callState: "ended")
                            viewState = .profile
                        }
                    }
                )
            }
        }
        .onDisappear {
            stopQueuePolling()
            stopCallTimer()
        }
    }

    // MARK: - State 1: Profile + Book

    private var profileView: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            if isLoading {
                ProgressView()
                    .tint(Color.cosmicGold)
                    .frame(height: 120)
            } else if let status = status {
                // Header
                HStack(spacing: Cosmic.Spacing.sm) {
                    // Avatar circle
                    ZStack {
                        Circle()
                            .fill(Color.cosmicGold.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.cosmicGold)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text(status.shastriji.name)
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        HStack(spacing: Cosmic.Spacing.xxs) {
                            starsView(rating: status.shastriji.rating)
                            Text(String(format: "%.1f", status.shastriji.rating))
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicGold)
                            Text("(\(status.shastriji.reviewCount))")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        Text("25 years experience")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(status.shastriji.name), rated \(String(format: "%.1f", status.shastriji.rating)) stars, \(status.shastriji.reviewCount) reviews, 25 years experience")

                // Specialization tags
                if !status.shastriji.specializations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            ForEach(status.shastriji.specializations, id: \.self) { spec in
                                Text(spec)
                                    .cosmicChip(
                                        background: Color.cosmicGold.opacity(0.1),
                                        foreground: Color.cosmicGold
                                    )
                            }
                        }
                    }
                }

                // Status indicator + queue
                HStack(spacing: Cosmic.Spacing.sm) {
                    // Online / offline status
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Circle()
                            .fill(status.isOnline ? Color.cosmicSuccess : Color.cosmicWarning)
                            .frame(width: 8, height: 8)
                        if status.isOnline {
                            Text("Available now")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicSuccess)
                        } else if let nextSlot = status.nextSlotTime {
                            Text("Next slot: \(nextSlot)")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicWarning)
                        } else {
                            Text("Offline")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicWarning)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Spacer()

                    // Queue length
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text(status.currentQueueLength > 0
                             ? "\(status.currentQueueLength) waiting"
                             : "No wait")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(status.currentQueueLength > 0
                                        ? "\(status.currentQueueLength) people waiting"
                                        : "No wait time")
                }

                // Error message
                if let errorMessage = errorMessage {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.cosmicError)
                        Text(errorMessage)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicError)
                    }
                }

                // CTA button
                Button {
                    Task { await bookConsultation() }
                } label: {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        if isBooking {
                            ProgressView()
                                .tint(Color.cosmicVoid)
                        }
                        Text("Book Free Consultation")
                    }
                }
                .buttonStyle(.cosmicPrimary)
                .disabled(!status.isOnline || isBooking)
                .accessibilityLabel("Book free consultation with \(status.shastriji.name)")
                .accessibilityHint(status.isOnline
                                   ? "Double tap to join the queue"
                                   : "Currently unavailable")
            } else {
                // Error state
                VStack(spacing: Cosmic.Spacing.sm) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text("Could not load status")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Button("Retry") {
                        Task { await loadStatus() }
                    }
                    .buttonStyle(.cosmicGhost)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Cosmic.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Could not load Shastriji status. Double tap to retry.")
            }
        }
    }

    // MARK: - State 2: In Queue

    private func queueView(position: Int, waitMinutes: Int) -> some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            // Queue position
            VStack(spacing: Cosmic.Spacing.xs) {
                Text("#\(position)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cosmicGold)
                    .accessibilityLabel("Queue position \(position)")

                Text("Your position in queue")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            // Estimated wait
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cosmicGold)
                Text("~\(waitMinutes) minutes")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Estimated wait time: approximately \(waitMinutes) minutes")

            // Progress indicator
            ProgressView()
                .tint(Color.cosmicGold)
                .scaleEffect(1.2)

            Text("We will notify you when Shastriji is ready")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.center)

            // Cancel button
            Button {
                cancelBooking()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(.cosmicSecondary)
            .accessibilityLabel("Cancel consultation booking")
        }
        .padding(.vertical, Cosmic.Spacing.sm)
    }

    // MARK: - State 3a: Call Ready

    private var callReadyView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            // Pulsing glow
            ZStack {
                Circle()
                    .fill(Color.cosmicGold.opacity(pulseAnimation ? 0.2 : 0.05))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)

                Circle()
                    .fill(Color.cosmicGold.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: "phone.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.cosmicGold)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            .accessibilityHidden(true)

            Text("Shastriji is ready!")
                .font(.cosmicTitle3)
                .foregroundStyle(Color.cosmicGold)

            Text("Your consultation is about to begin")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)

            Button {
                joinCall()
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "video.fill")
                    Text("Join Video Call")
                }
            }
            .buttonStyle(.cosmicPrimary)
            .accessibilityLabel("Join video call with Shastriji")

            if let error = errorMessage {
                Text(error)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicError)
                    .multilineTextAlignment(.center)
                    .padding(.top, Cosmic.Spacing.xs)
            }
        }
        .padding(.vertical, Cosmic.Spacing.sm)
    }

    // MARK: - State 3b: In Call

    private var inCallView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            // Call indicator
            HStack(spacing: Cosmic.Spacing.xs) {
                Circle()
                    .fill(Color.cosmicSuccess)
                    .frame(width: 10, height: 10)
                Text("In session with Shastriji")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicSuccess)
            }
            .accessibilityElement(children: .combine)

            // Duration timer
            Text(formattedDuration)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.cosmicTextPrimary)
                .accessibilityLabel("Call duration: \(formattedDurationAccessible)")

            // End call button
            Button {
                endCall()
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "phone.down.fill")
                    Text("End Call")
                }
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(.white)
                .frame(height: Cosmic.ButtonHeight.large)
                .frame(maxWidth: .infinity)
                .background(Color.cosmicError)
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            }
            .accessibilityLabel("End call with Shastriji")
        }
        .padding(.vertical, Cosmic.Spacing.sm)
    }

    // MARK: - Helpers

    private func starsView(rating: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating ? "star.fill" : (Double(star) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.cosmicGold)
            }
        }
        .accessibilityHidden(true)
    }

    private var formattedDuration: String {
        let minutes = callDurationSeconds / 60
        let seconds = callDurationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var formattedDurationAccessible: String {
        let minutes = callDurationSeconds / 60
        let seconds = callDurationSeconds % 60
        if minutes > 0 {
            return "\(minutes) minutes and \(seconds) seconds"
        }
        return "\(seconds) seconds"
    }

    // MARK: - API Actions

    @MainActor
    private func loadStatus() async {
        isLoading = true
        errorMessage = nil
        do {
            status = try await APIServices.shared.getShastrijiStatus()
        } catch {
            status = nil
        }
        isLoading = false
    }

    @MainActor
    private func bookConsultation() async {
        isBooking = true
        errorMessage = nil
        do {
            let response = try await APIServices.shared.bookShastriji()
            viewState = .inQueue(
                bookingId: response.bookingId,
                position: response.queuePosition,
                waitMinutes: response.estimatedWaitMinutes
            )

            Analytics.shared.track(.templeBookingStarted, properties: [
                "type": "shastriji_consultation",
                "queue_position": "\(response.queuePosition)"
            ])

            startQueuePolling(bookingId: response.bookingId)
        } catch {
            errorMessage = "Could not book. Please try again."
        }
        isBooking = false
    }

    private func cancelBooking() {
        stopQueuePolling()
        viewState = .profile
        Task { await loadStatus() }
    }

    private func joinCall() {
        if case let .callReady(bookingId) = viewState {
            Task {
                do {
                    let sessionResponse = try await APIServices.shared.generatePoojaSessionLink(bookingId: bookingId)
                    sessionURL = sessionResponse.sessionLink

                    _ = try? await APIServices.shared.updateCallState(bookingId: bookingId, callState: "connected")

                    viewState = .inCall(bookingId: bookingId)
                    startCallTimer()
                    showCallView = true

                    Analytics.shared.track(.templeBookingCompleted, properties: [
                        "type": "shastriji_consultation",
                        "booking_id": bookingId
                    ])
                } catch {
                    errorMessage = "Could not start call. Please try again."
                    viewState = .callReady(bookingId: bookingId)
                }
            }
        }
    }

    private func endCall() {
        stopCallTimer()
        showCallView = false
        sessionURL = nil
        if case let .inCall(bookingId) = viewState {
            Task {
                _ = try? await APIServices.shared.updateCallState(bookingId: bookingId, callState: "ended")
            }
        }
        viewState = .profile
        Task { await loadStatus() }
    }

    // MARK: - Polling

    private func startQueuePolling(bookingId: String) {
        stopQueuePolling()
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await pollQueue()
            }
        }
        queueTimer = timer
    }

    private func stopQueuePolling() {
        queueTimer?.invalidate()
        queueTimer = nil
    }

    @MainActor
    private func pollQueue() async {
        do {
            let queueStatus = try await APIServices.shared.getShastrijiQueue()

            if queueStatus.callState == "ringing" || queueStatus.callState == "ready" {
                stopQueuePolling()
                viewState = .callReady(bookingId: queueStatus.bookingId)
                CosmicHaptics.success()
            } else if queueStatus.callState == "cancelled" || queueStatus.callState == "completed" {
                stopQueuePolling()
                viewState = .profile
                await loadStatus()
            } else {
                viewState = .inQueue(
                    bookingId: queueStatus.bookingId,
                    position: queueStatus.queuePosition,
                    waitMinutes: queueStatus.estimatedWaitMinutes
                )
            }
        } catch {
            // Keep current state on transient errors
        }
    }

    // MARK: - Call Timer

    private func startCallTimer() {
        stopCallTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            callDurationSeconds += 1
        }
        callTimer = timer
    }

    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
        callDurationSeconds = 0
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()
        ScrollView {
            ShastrijiConsultView()
                .environmentObject(GamificationManager())
        }
    }
}
