import SwiftUI

struct LogoAnimationView: View {
    @State private var spiralProgress: CGFloat = 0
    @State private var planetScale: CGFloat = 0
    @State private var nodeOpacity: Double = 0
    @State private var starBurstRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Logarithmic spiral path
            SpiralPath()
                .trim(from: 0, to: spiralProgress)
                .stroke(
                    Color(hex: "0A3AFF"),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-45))
                .animation(.easeOut(duration: 1), value: spiralProgress)
            
            // Planet at center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "4D7FFF"),
                            Color(hex: "0A3AFF")
                        ],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 40, height: 40)
                .scaleEffect(planetScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: planetScale)
            
            // Star burst
            Image(systemName: "sparkle")
                .foregroundColor(Color(hex: "FFB400"))
                .font(.system(size: 20))
                .opacity(nodeOpacity)
                .rotationEffect(.degrees(starBurstRotation))
                .animation(.easeInOut(duration: 0.3), value: nodeOpacity)
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: starBurstRotation)
            
            // Lagrange point node
            Circle()
                .fill(Color(hex: "FFB400"))
                .frame(width: 12, height: 12)
                .offset(x: 65, y: -55)
                .opacity(nodeOpacity)
                .animation(.easeInOut(duration: 0.3).delay(0.8), value: nodeOpacity)
        }
        .onAppear {
            // Animate the logo drawing
            withAnimation {
                spiralProgress = 1
            }
            
            // Animate planet appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                planetScale = 1
            }
            
            // Animate nodes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                nodeOpacity = 1
                starBurstRotation = 360
            }
        }
    }
}

// Custom spiral path shape
struct SpiralPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let scale = rect.width / 1024
        
        // Logarithmic spiral points
        let points: [(x: CGFloat, y: CGFloat)] = [
            (512, 432), (592, 432), (656, 456),
            (720, 480), (768, 528), (816, 576),
            (840, 640), (864, 704), (864, 768),
            (864, 832), (832, 888), (800, 944),
            (736, 976), (672, 1008), (592, 1008),
            (512, 1008), (432, 976), (352, 944),
            (288, 880), (224, 816), (192, 736),
            (160, 656), (160, 576), (160, 496),
            (200, 424), (240, 352), (312, 304),
            (384, 256), (472, 240), (560, 224),
            (648, 240), (736, 256), (808, 304),
            (880, 352), (920, 424)
        ]
        
        // Convert to scaled path
        if !points.isEmpty {
            let start = CGPoint(
                x: (points[0].x - 512) * scale + center.x,
                y: (points[0].y - 512) * scale + center.y
            )
            path.move(to: start)
            
            for i in stride(from: 1, to: points.count, by: 3) {
                guard i + 2 < points.count else { break }
                
                let control1 = CGPoint(
                    x: (points[i].x - 512) * scale + center.x,
                    y: (points[i].y - 512) * scale + center.y
                )
                let control2 = CGPoint(
                    x: (points[i + 1].x - 512) * scale + center.x,
                    y: (points[i + 1].y - 512) * scale + center.y
                )
                let end = CGPoint(
                    x: (points[i + 2].x - 512) * scale + center.x,
                    y: (points[i + 2].y - 512) * scale + center.y
                )
                
                path.addCurve(to: end, control1: control1, control2: control2)
            }
        }
        
        return path
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct LogoAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        LogoAnimationView()
            .frame(width: 300, height: 300)
            .background(Color.black)
    }
}