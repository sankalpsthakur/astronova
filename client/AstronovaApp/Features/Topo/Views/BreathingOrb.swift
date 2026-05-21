import SwiftUI

struct BreathingOrb: View {
    let breath: PauseBreath
    let tint: Color
    var onComplete: () -> Void

    @State private var scale: CGFloat = 0.55
    @State private var glow: CGFloat = 0.4
    @State private var phase: Phase = .idle
    @State private var roundsRemaining: Int = 0
    @State private var phaseLabel: String = "ready"
    @State private var task: Task<Void, Never>?

    enum Phase: Equatable {
        case idle, inhale, hold, exhale, gap, done
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .scaleEffect(scale * 1.15)
                    .blur(radius: 32)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.85), tint.opacity(0.35)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 140
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(scale)
                    .shadow(color: tint.opacity(glow), radius: 40)

                VStack(spacing: 4) {
                    Text(phaseLabel)
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.cosmicTextPrimary.opacity(0.85))
                    if phase != .idle && phase != .done {
                        Text("round \(currentRound) of \(breath.rounds)")
                            .font(.cosmicLabel)
                            .foregroundStyle(Color.cosmicTextSecondary.opacity(0.7))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: phaseLabel)

            Spacer()

            if phase == .done {
                Text("Done.")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(tint)
                    .transition(.opacity)
            }
        }
        .onAppear {
            start()
        }
        .onDisappear {
            task?.cancel()
        }
    }

    private var currentRound: Int {
        max(1, breath.rounds - roundsRemaining + 1)
    }

    private func start() {
        task?.cancel()
        roundsRemaining = breath.rounds
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            await runCycles()
        }
    }

    @MainActor
    private func runCycles() async {
        for _ in 0..<breath.rounds {
            if Task.isCancelled { return }
            await runOneRound()
            roundsRemaining -= 1
        }
        if !Task.isCancelled {
            phase = .done
            phaseLabel = "complete"
            HapticFeedbackService.shared.success()
            try? await Task.sleep(nanoseconds: 600_000_000)
            onComplete()
        }
    }

    @MainActor
    private func runOneRound() async {
        // Inhale
        phase = .inhale
        phaseLabel = "breathe in"
        HapticFeedbackService.shared.lightImpact()
        withAnimation(.easeInOut(duration: TimeInterval(breath.inhale))) {
            scale = 1.0
            glow = 0.9
        }
        try? await Task.sleep(nanoseconds: UInt64(breath.inhale) * 1_000_000_000)
        if Task.isCancelled { return }

        // Hold (if present)
        if let hold = breath.hold, hold > 0 {
            phase = .hold
            phaseLabel = "hold"
            try? await Task.sleep(nanoseconds: UInt64(hold) * 1_000_000_000)
            if Task.isCancelled { return }
        }

        // Exhale
        phase = .exhale
        phaseLabel = breath.exhaleSound.map { "exhale — \"\($0)\"" } ?? "breathe out"
        HapticFeedbackService.shared.mediumImpact()
        withAnimation(.easeInOut(duration: TimeInterval(breath.exhale))) {
            scale = 0.55
            glow = 0.3
        }
        try? await Task.sleep(nanoseconds: UInt64(breath.exhale) * 1_000_000_000)
    }
}
