import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BrandLogoView: View {
    var size: CGFloat = 56
    
    var body: some View {
        Group {
            if hasImageAsset {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .accessibilityLabel("Astronova logo")
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.4), Color.indigo.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size
                            )
                        )
                        .frame(width: size, height: size)
                    
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [.purple, .blue, .cyan, .purple]),
                                center: .center
                            ),
                            lineWidth: max(2, size * 0.05)
                        )
                        .frame(width: size * 0.9, height: size * 0.9)
                        .blur(radius: 0.2)
                    
                    // Nova star glyph (fallback)
                    StarShape(points: 8, innerRatio: 0.42)
                        .fill(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.55, height: size * 0.55)
                        .shadow(color: .cyan.opacity(0.4), radius: 4, y: 2)
                }
                .accessibilityLabel("Astronova logo")
            }
        }
    }
    
    private var hasImageAsset: Bool {
        #if canImport(UIKit)
        return UIImage(named: "BrandLogo") != nil
        #else
        return false
        #endif
    }
}

private struct StarShape: Shape {
    let points: Int
    let innerRatio: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        var path = Path()
        var angle = -CGFloat.pi / 2
        let angleIncrement = .pi / CGFloat(points)
        var firstPoint = true
        for _ in 0..<(points * 2) {
            let radius = (firstPoint ? outerRadius : innerRadius)
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if firstPoint {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            firstPoint.toggle()
            angle += angleIncrement
        }
        path.closeSubpath()
        return path
    }
}
