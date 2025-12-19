import SwiftUI

/// Enhanced loading view with cosmic-themed animations and multiple states
struct LoadingView: View {
    enum LoadingStyle {
        case standard
        case cosmic
        case inline
        case overlay
        case skeleton(SkeletonType)
    }
    
    enum SkeletonType {
        case horoscope
        case chart
        case profile
        case locationSearch
    }
    
    let style: LoadingStyle
    let message: String?
    @State private var animateStars = false
    @State private var animateRotation = false
    
    init(style: LoadingStyle = .standard, message: String? = nil) {
        self.style = style
        self.message = message
    }
    
    var body: some View {
        Group {
            switch style {
            case .standard:
                standardLoadingView
            case .cosmic:
                cosmicLoadingView
            case .inline:
                inlineLoadingView
            case .overlay:
                overlayLoadingView
            case .skeleton(let skeletonType):
                skeletonView(for: skeletonType)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateStars = true
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animateRotation = true
            }
        }
    }
    
    private var standardLoadingView: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.cosmicGold)

            if let message = message {
                Text(message)
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
    }
    
    private var cosmicLoadingView: some View {
        VStack(spacing: Cosmic.Spacing.screen) {
            ZStack {
                // Outer cosmic ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cosmicAmethyst.opacity(0.4), Color.cosmicGold.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(animateRotation ? 360 : 0))

                // Inner pulsing stars
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(Color.cosmicTextPrimary.opacity(0.8))
                        .frame(width: 3, height: 3)
                        .offset(x: 20)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .scaleEffect(animateStars ? 1.2 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                            value: animateStars
                        )
                }

                // Central sparkle
                Text("✨")
                    .font(.cosmicHeadline)
                    .scaleEffect(animateStars ? 1.3 : 0.8)
            }

            if let message = message {
                Text(message)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(LinearGradient.cosmicCoolGradient)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var inlineLoadingView: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(Color.cosmicGold)

            if let message = message {
                Text(message)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
    }
    
    private var overlayLoadingView: some View {
        ZStack {
            Color.cosmicVoid.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: Cosmic.Spacing.md) {
                cosmicLoadingView

                if let message = message {
                    Text(message)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(Cosmic.Spacing.lg)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            .cosmicElevation(.medium)
        }
    }
    
    @ViewBuilder
    private func skeletonView(for type: SkeletonType) -> some View {
        switch type {
        case .horoscope:
            HoroscopeSkeleton()
        case .chart:
            PlanetaryChartSkeleton()
        case .profile:
            ProfileSetupSkeleton()
        case .locationSearch:
            LocationSearchSkeleton()
        }
    }
}

// MARK: - Skeleton Components

struct HoroscopeSkeleton: View {
    var body: some View {
        VStack(spacing: Cosmic.Spacing.screen) {
            // Title skeleton
            HStack {
                Rectangle()
                    .fill(Color.cosmicNebula)
                    .frame(width: 150, height: 24)
                    .cornerRadius(Cosmic.Radius.subtle)
                Spacer()
                Rectangle()
                    .fill(Color.cosmicNebula)
                    .frame(width: 80, height: 20)
                    .cornerRadius(Cosmic.Radius.subtle)
            }

            // Content blocks
            VStack(spacing: Cosmic.Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                        Rectangle()
                            .fill(Color.cosmicNebula)
                            .frame(width: 100, height: 18)
                            .cornerRadius(Cosmic.Radius.subtle)
                        VStack(spacing: Cosmic.Spacing.xxs) {
                            ForEach(0..<4, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.cosmicNebula)
                                    .frame(height: 14)
                                    .cornerRadius(2)
                            }
                        }
                    }
                    .padding(Cosmic.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                            .fill(Color.cosmicStardust.opacity(0.3))
                    )
                }
            }
        }
    }
}

struct PlanetaryChartSkeleton: View {
    var body: some View {
        VStack(spacing: Cosmic.Spacing.screen) {
            Circle()
                .fill(Color.cosmicNebula)
                .frame(width: 200, height: 200)
            Rectangle()
                .fill(Color.cosmicNebula)
                .frame(height: 100)
                .cornerRadius(Cosmic.Radius.subtle)
        }
    }
}

struct ProfileSetupSkeleton: View {
    var body: some View {
        VStack(spacing: Cosmic.Spacing.screen) {
            Rectangle()
                .fill(Color.cosmicNebula)
                .frame(height: 40)
                .cornerRadius(Cosmic.Radius.subtle)
            Rectangle()
                .fill(Color.cosmicNebula)
                .frame(height: 40)
                .cornerRadius(Cosmic.Radius.subtle)
        }
    }
}

struct LocationSearchSkeleton: View {
    var body: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(Color.cosmicNebula)
                    .frame(height: 50)
                    .cornerRadius(Cosmic.Radius.subtle)
            }
        }
    }
}

/// Compatibility wrapper for basic loading indicator
struct BasicLoadingView: View {
    var body: some View {
        Group {
            if #available(iOS 14.0, *) {
                ProgressView()
            } else {
                Text("Loading…")
            }
        }
    }
}