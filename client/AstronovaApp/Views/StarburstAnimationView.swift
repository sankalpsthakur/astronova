import SwiftUI

/// Starburst animation view using SwiftUI Canvas for cosmic effects
struct StarburstAnimationView: View {
    enum StarburstStyle {
        case celebration
        case cosmic
        case subtle
    }
    
    let style: StarburstStyle
    let duration: Double
    let particleCount: Int
    
    @State private var animationPhase = 0.0
    @State private var isAnimating = false
    
    init(style: StarburstStyle = .cosmic, duration: Double = 0.3, particleCount: Int = 12) {
        self.style = style
        self.duration = duration
        self.particleCount = particleCount
    }
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2
            
            for i in 0..<particleCount {
                let angle = Double(i) * (2 * .pi / Double(particleCount))
                let progress = animationPhase
                
                // Calculate particle position
                let distance = maxRadius * progress
                let x = center.x + cos(angle) * distance
                let y = center.y + sin(angle) * distance
                
                // Calculate particle properties based on style
                let (size, opacity, color) = particleProperties(for: style, progress: progress, index: i)
                
                // Draw particle
                let particleRect = CGRect(
                    x: x - size / 2,
                    y: y - size / 2,
                    width: size,
                    height: size
                )
                
                context.fill(
                    Path(ellipseIn: particleRect),
                    with: .color(color.opacity(opacity))
                )
                
                // Add sparkle effect for cosmic style
                if style == .cosmic && progress > 0.3 {
                    drawSparkle(context: context, at: CGPoint(x: x, y: y), size: size * 0.5, opacity: opacity * 0.7)
                }
            }
            
            // Central glow effect
            if style != .subtle {
                let glowRadius = maxRadius * 0.3 * (1 - animationPhase)
                let glowOpacity = (1 - animationPhase) * 0.8
                
                let glowRect = CGRect(
                    x: center.x - glowRadius,
                    y: center.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                )
                
                let glowColor = style == .cosmic ? Color.purple : Color.yellow
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(glowColor.opacity(glowOpacity))
                )
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: duration)) {
                    animationPhase = 1.0
                }
            } else {
                animationPhase = 0.0
            }
        }
    }
    
    private func particleProperties(for style: StarburstStyle, progress: Double, index: Int) -> (size: Double, opacity: Double, color: Color) {
        let baseSize: Double
        let baseOpacity: Double
        let color: Color
        
        switch style {
        case .celebration:
            baseSize = Double.random(in: 4...8)
            baseOpacity = 1.0
            color = [.yellow, .orange, .red, .pink].randomElement() ?? .yellow
            
        case .cosmic:
            baseSize = Double.random(in: 2...6)
            baseOpacity = 0.9
            color = [.purple, .blue, .cyan, .white].randomElement() ?? .purple
            
        case .subtle:
            baseSize = Double.random(in: 1...3)
            baseOpacity = 0.6
            color = .white
        }
        
        // Fade out as particles move away
        let opacity = baseOpacity * (1 - progress) * (1 - progress)
        
        // Vary size based on progress
        let size = baseSize * (1 + progress * 0.5)
        
        return (size, opacity, color)
    }
    
    private func drawSparkle(context: GraphicsContext, at point: CGPoint, size: Double, opacity: Double) {
        let sparkleColor = Color.white.opacity(opacity)
        
        // Draw four-pointed star
        let path = Path { path in
            path.move(to: CGPoint(x: point.x, y: point.y - size))
            path.addLine(to: CGPoint(x: point.x + size * 0.3, y: point.y - size * 0.3))
            path.addLine(to: CGPoint(x: point.x + size, y: point.y))
            path.addLine(to: CGPoint(x: point.x + size * 0.3, y: point.y + size * 0.3))
            path.addLine(to: CGPoint(x: point.x, y: point.y + size))
            path.addLine(to: CGPoint(x: point.x - size * 0.3, y: point.y + size * 0.3))
            path.addLine(to: CGPoint(x: point.x - size, y: point.y))
            path.addLine(to: CGPoint(x: point.x - size * 0.3, y: point.y - size * 0.3))
            path.closeSubpath()
        }
        
        context.fill(path, with: .color(sparkleColor))
    }
    
    func startAnimation() {
        isAnimating = true
    }
    
    func resetAnimation() {
        isAnimating = false
        animationPhase = 0.0
    }
}

/// View modifier to add starburst effect on tap or action
struct StarburstEffectModifier: ViewModifier {
    let style: StarburstAnimationView.StarburstStyle
    let duration: Double
    
    @State private var showStarburst = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showStarburst {
                        StarburstAnimationView(style: style, duration: duration)
                            .allowsHitTesting(false)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                    showStarburst = false
                                }
                            }
                    }
                }
            )
            .onTapGesture {
                showStarburst = true
            }
    }
}

extension View {
    /// Adds a starburst effect when the view is tapped
    func starburstEffect(style: StarburstAnimationView.StarburstStyle = .cosmic, duration: Double = 0.3) -> some View {
        modifier(StarburstEffectModifier(style: style, duration: duration))
    }
}

#Preview {
    VStack(spacing: 40) {
        StarburstAnimationView(style: .cosmic)
            .frame(width: 200, height: 200)
        
        Button("Tap for Starburst") {
            // This will be handled by the modifier
        }
        .padding()
        .background(.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .starburstEffect(style: .celebration)
    }
    .padding()
    .background(.black)
}