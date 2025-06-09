import SwiftUI

/// Enhanced loading view with cosmic-themed animations and multiple states
struct LoadingView: View {
    enum LoadingStyle {
        case standard
        case cosmic
        case inline
        case overlay
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
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var cosmicLoadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer cosmic ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3), .clear],
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
                        .fill(.white.opacity(0.8))
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
                    .font(.title3)
                    .scaleEffect(animateStars ? 1.3 : 0.8)
            }
            
            if let message = message {
                Text(message)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var inlineLoadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var overlayLoadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                cosmicLoadingView
                
                if let message = message {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
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