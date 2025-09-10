import SwiftUI

/// Cosmic color system for Astronova app
extension Color {
    
    // MARK: - Primary Brand Colors
    
    /// Deep cosmos navy (light) / Celestial purple (dark)
    static let cosmicPrimary = Color("CosmicPrimary")
    
    /// Starlight blue (light) / Nebula blue (dark)
    static let cosmicSecondary = Color("CosmicSecondary")
    
    /// Aurora gold - consistent across themes
    static let cosmicAccent = Color("CosmicAccent")
    
    // MARK: - Surface Colors
    
    /// Pearl white (light) / Deep space (dark)
    static let cosmicSurface = Color("CosmicSurface")
    
    /// Cloud silver (light) / Void gray (dark)
    static let cosmicSurfaceSecondary = Color("CosmicSurfaceSecondary")
    
    // MARK: - Text Colors
    
    /// Cosmic black (light) / Starlight white (dark)
    static let cosmicTextPrimary = Color("CosmicTextPrimary")
    
    /// Stellar gray (light) / Cosmic silver (dark)
    static let cosmicTextSecondary = Color("CosmicTextSecondary")
}

// MARK: - Gradient Definitions

extension LinearGradient {
    
    /// Primary cosmic gradient
    static let cosmicPrimary = LinearGradient(
        colors: [Color.cosmicPrimary, Color.cosmicSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}