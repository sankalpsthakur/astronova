import Foundation

// MARK: - Astronova shared user-facing copy
// Single source of truth for short legal / regulatory phrases that appear in
// multiple surfaces. Keep wording terse so it fits as a one-line caption
// without wrapping past two lines on iPhone SE.
enum AstronovaCopy {
    /// Short disclaimer surfaced near birth-data entry and on the Self tab
    /// hero. Mirrors the long-form copy in PrivacyPolicyView's
    /// `disclaimerSection`, but compact enough for inline display.
    static let shortAstrologyDisclaimer =
        "Astrology insights are for reflection and entertainment, not medical, financial, or psychological advice."
}
