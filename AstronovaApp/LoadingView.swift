import SwiftUI

/// Compatibility wrapper for an indeterminate loading indicator.
/// Uses `ProgressView` on iOS 14+ and falls back to plain text on iOS 13.
struct LoadingView: View {
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