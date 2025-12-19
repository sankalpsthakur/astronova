import SwiftUI

// MARK: - Cosmic Motion System
// Animation presets, scroll behaviors, and interaction patterns

// MARK: - Animation Timing

enum CosmicTiming {
    /// 100ms - Micro feedback (haptics, subtle state changes)
    static let instant: Double = 0.1
    /// 200ms - Quick transitions (button states, toggles)
    static let quick: Double = 0.2
    /// 300ms - Standard transitions (most UI changes)
    static let standard: Double = 0.3
    /// 400ms - Moderate transitions (reveals, expansions)
    static let moderate: Double = 0.4
    /// 600ms - Dramatic transitions (celebrations, hero animations)
    static let dramatic: Double = 0.6
    /// 2000ms - Ambient looping effects
    static let ambient: Double = 2.0
    /// 4000ms - Slow ambient effects
    static let slowAmbient: Double = 4.0
}

// MARK: - Animation Extensions

extension Animation {

    // MARK: - Preset Animations

    /// Quick easeOut for instant feedback (100ms)
    static var cosmicInstant: Animation {
        .easeOut(duration: CosmicTiming.instant)
    }

    /// Quick easeInOut for button states (200ms)
    static var cosmicQuick: Animation {
        .easeInOut(duration: CosmicTiming.quick)
    }

    /// Standard smooth animation (300ms)
    static var cosmicSmooth: Animation {
        .easeInOut(duration: CosmicTiming.standard)
    }

    /// Reveal animation with easeOut (400ms)
    static var cosmicReveal: Animation {
        .easeOut(duration: CosmicTiming.moderate)
    }

    /// Dramatic animation for celebrations (600ms)
    static var cosmicDramatic: Animation {
        .easeOut(duration: CosmicTiming.dramatic)
    }

    /// Spring animation - responsive and natural
    static var cosmicSpring: Animation {
        .spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.25)
    }

    /// Bouncy spring for playful interactions
    static var cosmicBounce: Animation {
        .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2)
    }

    /// Snappy spring for quick interactions
    static var cosmicSnappy: Animation {
        .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.15)
    }

    /// Gentle spring for subtle movements
    static var cosmicGentle: Animation {
        .spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.3)
    }

    /// Ambient looping animation
    static var cosmicAmbient: Animation {
        .easeInOut(duration: CosmicTiming.ambient).repeatForever(autoreverses: true)
    }

    /// Slow ambient animation
    static var cosmicSlowAmbient: Animation {
        .easeInOut(duration: CosmicTiming.slowAmbient).repeatForever(autoreverses: true)
    }

    // MARK: - Staggered Animations

    /// Create staggered delay for list items
    static func cosmicStaggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .cosmicReveal.delay(Double(index) * baseDelay)
    }

    /// Create staggered spring for list items
    static func cosmicStaggeredSpring(index: Int, baseDelay: Double = 0.05) -> Animation {
        .cosmicSpring.delay(Double(index) * baseDelay)
    }
}

// MARK: - Transition Extensions

extension AnyTransition {

    /// Fade + scale for elegant appearance
    static var cosmicScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }

    /// Slide up + fade for content reveals
    static var cosmicSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Slide from leading edge
    static var cosmicSlideLeading: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Slide from trailing edge
    static var cosmicSlideTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// Blur + fade for mystical appearance
    static var cosmicBlur: AnyTransition {
        .modifier(
            active: BlurModifier(blur: 8, opacity: 0),
            identity: BlurModifier(blur: 0, opacity: 1)
        )
    }

    /// Scale + blur for dramatic reveals
    static var cosmicDramaticReveal: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: ScaleBlurModifier(scale: 0.8, blur: 10, opacity: 0),
                identity: ScaleBlurModifier(scale: 1, blur: 0, opacity: 1)
            ),
            removal: .modifier(
                active: ScaleBlurModifier(scale: 0.95, blur: 5, opacity: 0),
                identity: ScaleBlurModifier(scale: 1, blur: 0, opacity: 1)
            )
        )
    }
}

// MARK: - Transition Modifiers

private struct BlurModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
    }
}

private struct ScaleBlurModifier: ViewModifier {
    let scale: CGFloat
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - View Modifiers for Animation

extension View {

    /// Apply press effect (scale down on press)
    func cosmicPressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.cosmicQuick, value: isPressed)
    }

    /// Apply hover/focus effect
    func cosmicFocusEffect(isFocused: Bool) -> some View {
        self
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.cosmicSpring, value: isFocused)
    }

    /// Pulse animation for attention
    func cosmicPulse(_ isActive: Bool = true) -> some View {
        self
            .opacity(isActive ? 1.0 : 0.6)
            .animation(isActive ? .cosmicAmbient : .default, value: isActive)
    }

    /// Breathing glow effect
    func cosmicBreathingGlow(color: Color = .cosmicGold, isActive: Bool = true) -> some View {
        self.modifier(BreathingGlowModifier(color: color, isActive: isActive))
    }

    /// Floating animation
    func cosmicFloat(isActive: Bool = true, amount: CGFloat = 4) -> some View {
        self.modifier(FloatingModifier(isActive: isActive, amount: amount))
    }

    /// Rotate continuously
    func cosmicRotate(isActive: Bool = true, duration: Double = 8.0) -> some View {
        self.modifier(RotatingModifier(isActive: isActive, duration: duration))
    }

    /// Shimmer loading effect
    func cosmicShimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    /// Staggered appearance animation
    func cosmicStaggeredAppear(index: Int, isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.cosmicStaggered(index: index), value: isVisible)
    }

    /// Parallax scroll effect
    func cosmicParallax(offsetY: CGFloat, multiplier: CGFloat = 0.3) -> some View {
        self.offset(y: offsetY * multiplier)
    }
}

// MARK: - Animation Modifiers

private struct BreathingGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool
    @State private var glowAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowAmount * 0.3), radius: 8 + glowAmount * 4)
            .onAppear {
                guard isActive else { return }
                withAnimation(.cosmicSlowAmbient) {
                    glowAmount = 1
                }
            }
    }
}

private struct FloatingModifier: ViewModifier {
    let isActive: Bool
    let amount: CGFloat
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                guard isActive else { return }
                withAnimation(.cosmicAmbient) {
                    offset = -amount
                }
            }
    }
}

private struct RotatingModifier: ViewModifier {
    let isActive: Bool
    let duration: Double
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                guard isActive else { return }
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Scroll Behavior Helpers

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {

    /// Track scroll offset
    func cosmicTrackScroll(_ coordinateSpace: String = "scroll") -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpace)).minY
                )
            }
        )
    }

    /// Apply sticky header behavior
    func cosmicStickyHeader(scrollOffset: CGFloat, threshold: CGFloat = 50) -> some View {
        self
            .background(
                Color.cosmicBackground
                    .opacity(scrollOffset < -threshold ? 1 : 0)
            )
            .background(.ultraThinMaterial.opacity(scrollOffset < -threshold ? 1 : 0))
    }
}

// MARK: - Haptic Feedback

enum CosmicHaptics {
    /// Light impact for toggles and selections
    static func light() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    /// Medium impact for button taps
    static func medium() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    /// Heavy impact for significant actions
    static func heavy() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
    }

    /// Success notification
    static func success() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    /// Warning notification
    static func warning() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    /// Error notification
    static func error() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    /// Selection changed feedback
    static func selection() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}

// MARK: - Keyboard Animation Helpers

#if canImport(UIKit)
extension View {
    /// Animate with keyboard
    func cosmicKeyboardAnimation() -> some View {
        self.animation(.easeOut(duration: 0.25), value: UIResponder.currentFirstResponder != nil)
    }
}

extension UIResponder {
    static weak var currentFirstResponder: UIResponder?

    func findFirstResponder() {
        UIResponder.currentFirstResponder = self
    }
}
#endif

// MARK: - Loading States

enum CosmicLoadingStyle {
    case spinner
    case dots
    case pulse
    case constellation
}

struct CosmicLoadingView: View {
    let style: CosmicLoadingStyle
    @State private var isAnimating = false

    var body: some View {
        switch style {
        case .spinner:
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.cosmicGold, lineWidth: 3)
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }

        case .dots:
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.cosmicGold)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .onAppear { isAnimating = true }

        case .pulse:
            Circle()
                .fill(Color.cosmicGold.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }

        case .constellation:
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(Color.cosmicGold)
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(Double(index) * .pi * 2 / 5) * 16,
                            y: sin(Double(index) * .pi * 2 / 5) * 16
                        )
                        .opacity(isAnimating ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: isAnimating
                        )
                }
            }
            .onAppear { isAnimating = true }
        }
    }
}

// MARK: - Preview

#Preview("Cosmic Motion") {
    VStack(spacing: 32) {
        Text("Loading Styles")
            .font(.cosmicHeadline)

        HStack(spacing: 32) {
            VStack {
                CosmicLoadingView(style: .spinner)
                Text("Spinner").font(.cosmicCaption)
            }
            VStack {
                CosmicLoadingView(style: .dots)
                Text("Dots").font(.cosmicCaption)
            }
            VStack {
                CosmicLoadingView(style: .pulse)
                Text("Pulse").font(.cosmicCaption)
            }
            VStack {
                CosmicLoadingView(style: .constellation)
                Text("Constellation").font(.cosmicCaption)
            }
        }
    }
    .padding()
    .background(Color.cosmicBackground)
}
