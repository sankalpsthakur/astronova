import SwiftUI

struct ProtocolRunnerView: View {
    let proto: PauseProtocol
    let moodBefore: Int

    @Environment(\.dismiss) private var dismiss
    @StateObject private var log = PauseLogStore.shared

    @State private var stepIndex: Int = 0
    @State private var phase: Phase = .running
    @State private var bodyLocation: String? = nil
    @State private var routeChoice: PauseStepOption? = nil
    @State private var committedAction: String = ""
    @State private var ritualDone: Bool = false
    @State private var moodAfter: Double = 50

    enum Phase { case running, moodAfter, complete }

    private var tint: Color { planetTint(for: proto.planet) }
    private var currentStep: PauseStep { proto.steps[stepIndex] }
    private var isLastStep: Bool { stepIndex == proto.steps.count - 1 }

    var body: some View {
        ZStack {
            ambientBackground

            VStack(spacing: 0) {
                topBar

                switch phase {
                case .running:
                    runningView
                        .id(stepIndex)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                case .moodAfter:
                    moodAfterView
                case .complete:
                    completeView
                }
            }
        }
        .onAppear {
            HapticFeedbackService.shared.mediumImpact()
            moodAfter = Double(max(0, moodBefore - 15))
        }
    }

    // MARK: - Layers

    private var ambientBackground: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            RadialGradient(
                colors: [tint.opacity(0.25), Color.cosmicVoid],
                center: .top,
                startRadius: 60,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                logAbandon()
                HapticFeedbackService.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.cosmicSurface.opacity(0.7)))
            }
            Spacer()
            if phase == .running {
                progressDots
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<proto.steps.count, id: \.self) { i in
                Capsule()
                    .fill(i <= stepIndex ? tint : Color.cosmicSurfaceSecondary)
                    .frame(width: i == stepIndex ? 18 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.25), value: stepIndex)
            }
        }
    }

    // MARK: - Step Dispatch

    @ViewBuilder
    private var runningView: some View {
        switch stepKind {
        case .name:     nameStep
        case .locate:   locateStep
        case .breathe:  breatheStep
        case .reframe:  reframeStep
        case .route:    routeStep
        case .ritual:   ritualStep
        case .generic:  genericStep
        }
    }

    private enum StepKind { case name, locate, breathe, reframe, route, ritual, generic }

    private var stepKind: StepKind {
        if currentStep.breath != nil { return .breathe }
        let t = currentStep.title.lowercased()
        if t.contains("name") { return .name }
        if t.contains("locate") || t.contains("find") { return .locate }
        if t.contains("reframe") { return .reframe }
        if t.contains("route") { return .route }
        if t.contains("ritual") { return .ritual }
        return .generic
    }

    // MARK: - Step Views

    private var stepHeader: some View {
        VStack(spacing: 6) {
            Text(verbForTitle(currentStep.title))
                .font(.system(size: 12, weight: .semibold))
                .tracking(2.5)
                .textCase(.uppercase)
                .foregroundStyle(tint)
            Text("Step \(currentStep.index) of \(proto.steps.count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.cosmicTextTertiary)
        }
        .padding(.top, 4)
    }

    private var nameStep: some View {
        VStack(spacing: 28) {
            stepHeader
            Spacer()
            Text("Say it.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.cosmicTextSecondary)
            Text("\"I am feeling \(proto.emotion.lowercased()).\"")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("Out loud, or in your head. Don't justify it. Don't story it.")
                .font(.system(size: 13))
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            primaryButton("Said it") { advance() }
        }
        .padding(.bottom, 24)
    }

    private var locateStep: some View {
        VStack(spacing: 22) {
            stepHeader
            Spacer()
            Text("Where is it?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Put your hand there.")
                .font(.system(size: 14))
                .foregroundStyle(Color.cosmicTextSecondary)

            VStack(spacing: 10) {
                ForEach(locateOptions, id: \.self) { option in
                    Button {
                        bodyLocation = option
                        HapticFeedbackService.shared.selection()
                    } label: {
                        HStack {
                            Circle()
                                .fill(bodyLocation == option ? tint : tint.opacity(0.2))
                                .frame(width: 10, height: 10)
                            Text(option)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.cosmicTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.cosmicSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(bodyLocation == option ? tint : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    bodyLocation = "elsewhere"
                    HapticFeedbackService.shared.selection()
                } label: {
                    Text("elsewhere")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Spacer()
            primaryButton(bodyLocation == nil ? "Skip" : "Continue") { advance() }
        }
        .padding(.bottom, 24)
    }

    private var locateOptions: [String] {
        if let options = currentStep.options {
            return options.compactMap { $0.label }
        }
        return ["Heat in face, jaw, throat", "Chest, fists, shoulders", "Gut, belly, hips"]
    }

    private var breatheStep: some View {
        VStack(spacing: 16) {
            stepHeader
            if let breath = currentStep.breath {
                BreathingOrb(breath: breath, tint: tint, onComplete: {
                    advance()
                })
                .frame(maxHeight: .infinity)
                Button("Skip") { advance() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .padding(.bottom, 24)
            }
        }
    }

    private var reframeStep: some View {
        VStack(spacing: 24) {
            stepHeader
            Spacer()
            Text(reframeSentence)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.cosmicTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            primaryButton("Got it") { advance() }
        }
        .padding(.bottom, 24)
    }

    private var reframeSentence: String {
        let body = currentStep.body
        if body.count > 200, let firstSentence = body.split(separator: ".").first {
            return firstSentence + "."
        }
        return body
    }

    private var routeStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 6) {
                stepHeader
            }
            .frame(maxWidth: .infinity)

            Text("Pick one move.")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(routeOptions) { option in
                        RouteChoiceCard(
                            option: option,
                            tint: tint,
                            isSelected: routeChoice?.id == option.id,
                            onTap: {
                                routeChoice = option
                                committedAction = option.action ?? option.label ?? ""
                                HapticFeedbackService.shared.selection()
                            }
                        )
                    }
                    if routeOptions.isEmpty {
                        Text(currentStep.body)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 16)
            }

            primaryButton(routeChoice == nil ? "Continue" : "I'll do this") {
                advance()
            }
        }
        .padding(.bottom, 24)
    }

    private var routeOptions: [PauseStepOption] {
        currentStep.options ?? []
    }

    private var ritualStep: some View {
        VStack(spacing: 22) {
            stepHeader
            Spacer()
            Text("Discharge through the body.")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
            Text(currentStep.body)
                .font(.system(size: 14))
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack(spacing: 12) {
                Button {
                    ritualDone = false
                    advance()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.cosmicSurface)
                        )
                }
                .buttonStyle(.plain)
                Button {
                    ritualDone = true
                    HapticFeedbackService.shared.success()
                    advance()
                } label: {
                    Text("Did it")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(tint)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    private var genericStep: some View {
        VStack(spacing: 22) {
            stepHeader
            Spacer()
            ScrollView {
                Text(currentStep.body)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 28)
            }
            Spacer()
            primaryButton("Continue") { advance() }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Mood After + Complete

    private var moodAfterView: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Where are you now?")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)

            VStack(spacing: 18) {
                Text("\(Int(moodAfter))")
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(tint)

                Text(intensityWord(moodAfter))
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.cosmicTextSecondary)

                Slider(value: $moodAfter, in: 0...100, step: 1) { editing in
                    if !editing { HapticFeedbackService.shared.selection() }
                }
                .tint(tint)
                .padding(.horizontal, 36)

                HStack {
                    Text("calm")
                    Spacer()
                    Text("intense")
                }
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color.cosmicTextTertiary)
                .padding(.horizontal, 36)
            }

            Spacer()

            primaryButton("Finish") {
                HapticFeedbackService.shared.success()
                logSession()
                withAnimation { phase = .complete }
            }
        }
        .padding(.bottom, 24)
    }

    private var completeView: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 12) {
                Text("\(moodBefore) → \(Int(moodAfter))")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(tint)
                Text(deltaLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            if !committedAction.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR MOVE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(committedAction)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cosmicSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }

            if !proto.doNot.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DO NOT — NEXT \(proto.doNotWindowMinutes) MIN")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    ForEach(proto.doNot, id: \.self) { rule in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.slash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(tint.opacity(0.7))
                                .padding(.top, 2)
                            Text(rule)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }

            Spacer()

            primaryButton("Close") {
                HapticFeedbackService.shared.lightImpact()
                dismiss()
            }
        }
        .padding(.bottom, 24)
    }

    private var deltaLabel: String {
        let delta = moodBefore - Int(moodAfter)
        if delta >= 30 { return "Solid drop" }
        if delta >= 15 { return "Settling" }
        if delta >= 5  { return "Down a notch" }
        if delta >= -5 { return "Holding" }
        return "Still climbing — try another protocol"
    }

    // MARK: - Helpers

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.cosmicVoid)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint)
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private func verbForTitle(_ title: String) -> String {
        let t = title.lowercased()
        if t.contains("name") { return "NAME IT" }
        if t.contains("locate") || t.contains("find") { return "FIND IT" }
        if t.contains("breathe") { return "BREATHE WITH IT" }
        if t.contains("reframe") { return "WHAT IT'S FOR" }
        if t.contains("route") { return "PICK ONE MOVE" }
        if t.contains("ritual") { return "DISCHARGE" }
        return title.uppercased()
    }

    private func intensityWord(_ value: Double) -> String {
        switch value {
        case 0..<20:  return "Calm"
        case 20..<40: return "Settled"
        case 40..<60: return "Active"
        case 60..<80: return "Charged"
        default:      return "Overflowing"
        }
    }

    private func advance() {
        HapticFeedbackService.shared.lightImpact()
        if isLastStep {
            withAnimation(.easeOut(duration: 0.3)) { phase = .moodAfter }
        } else {
            withAnimation(.easeOut(duration: 0.25)) { stepIndex += 1 }
        }
    }

    private func logSession() {
        let entry = PauseLogEntry(
            id: UUID(),
            timestamp: Date(),
            protocolId: proto.id,
            emotion: proto.emotion,
            planet: proto.planet,
            moodBefore: moodBefore,
            moodAfter: Int(moodAfter),
            bodyLocation: bodyLocation,
            routeCondition: routeChoice?.condition,
            routeAction: routeChoice?.action,
            committedAction: committedAction.isEmpty ? nil : committedAction,
            abandonedAtStep: nil
        )
        log.append(entry)
    }

    private func logAbandon() {
        let entry = PauseLogEntry(
            id: UUID(),
            timestamp: Date(),
            protocolId: proto.id,
            emotion: proto.emotion,
            planet: proto.planet,
            moodBefore: moodBefore,
            moodAfter: nil,
            bodyLocation: bodyLocation,
            routeCondition: routeChoice?.condition,
            routeAction: routeChoice?.action,
            committedAction: nil,
            abandonedAtStep: stepIndex
        )
        log.append(entry)
    }
}

private struct RouteChoiceCard: View {
    let option: PauseStepOption
    let tint: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                if let condition = option.condition {
                    Text(condition)
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(tint)
                }
                if let action = option.action {
                    Text(action)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let label = option.label {
                    Text(label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.18) : Color.cosmicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint : Color.cosmicSurfaceSecondary.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
