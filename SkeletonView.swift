import SwiftUI

// MARK: - Skeleton View Components

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var shimmerPhase: CGFloat = 0
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerPhase)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius)
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerPhase = 300
                }
            }
    }
}

// MARK: - Skeleton Text Components

struct SkeletonText: View {
    let lines: Int
    let lineHeight: CGFloat
    let spacing: CGFloat
    
    init(lines: Int = 3, lineHeight: CGFloat = 16, spacing: CGFloat = 8) {
        self.lines = lines
        self.lineHeight = lineHeight
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonView(
                    width: index == lines - 1 ? 
                        CGFloat.random(in: 120...200) : 
                        CGFloat.random(in: 200...300),
                    height: lineHeight
                )
            }
        }
    }
}

// MARK: - Planetary Chart Skeleton

struct PlanetaryChartSkeleton: View {
    var body: some View {
        VStack(spacing: 24) {
            // Chart wheel skeleton
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 280, height: 280)
                
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: 120, height: 120)
                
                // Skeleton planetary positions
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .offset(
                            x: cos(Double(index) * .pi / 6) * 100,
                            y: sin(Double(index) * .pi / 6) * 100
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // Planetary positions list skeleton
            VStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonView(width: 80, height: 16)
                            SkeletonView(width: 120, height: 12)
                        }
                        
                        Spacer()
                        
                        SkeletonView(width: 60, height: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
            }
        }
    }
}

// MARK: - Horoscope Content Skeleton

struct HoroscopeSkeleton: View {
    var body: some View {
        VStack(spacing: 20) {
            // Title skeleton
            HStack {
                SkeletonView(width: 150, height: 24, cornerRadius: 6)
                Spacer()
                SkeletonView(width: 80, height: 20, cornerRadius: 4)
            }
            
            // Content blocks
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        SkeletonView(width: 100, height: 18, cornerRadius: 4)
                        SkeletonText(lines: 4, lineHeight: 14, spacing: 6)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
            }
        }
    }
}

// MARK: - Profile Setup Skeleton

struct ProfileSetupSkeleton: View {
    var body: some View {
        VStack(spacing: 24) {
            // Profile avatar skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
            
            // Form fields skeleton
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonView(width: 100, height: 16)
                        SkeletonView(width: nil, height: 44, cornerRadius: 8)
                    }
                }
            }
            
            // Button skeleton
            SkeletonView(width: nil, height: 50, cornerRadius: 25)
        }
        .padding(20)
    }
}

// MARK: - Location Search Skeleton

struct LocationSearchSkeleton: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { _ in
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(width: CGFloat.random(in: 120...200), height: 14)
                        SkeletonView(width: CGFloat.random(in: 80...150), height: 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        Text("Skeleton Components")
            .font(.title2.bold())
        
        ScrollView {
            VStack(spacing: 40) {
                VStack(alignment: .leading) {
                    Text("Planetary Chart")
                        .font(.headline)
                    PlanetaryChartSkeleton()
                }
                
                VStack(alignment: .leading) {
                    Text("Horoscope Content")
                        .font(.headline)
                    HoroscopeSkeleton()
                }
                
                VStack(alignment: .leading) {
                    Text("Profile Setup")
                        .font(.headline)
                    ProfileSetupSkeleton()
                }
            }
            .padding()
        }
    }
    .padding()
}