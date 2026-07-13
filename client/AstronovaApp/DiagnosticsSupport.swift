import Diagnostics
import Foundation

/// A deliberately small, allowlisted event trail for support reports.
/// Diagnostics' stdout/stderr capture is not enabled because application logs
/// can contain user-entered astrology context.
actor DiagnosticsSupportLog {
    static let shared = DiagnosticsSupportLog()

    private var events: [String] = []
    private let formatter = ISO8601DateFormatter()

    func record(_ message: String) {
        events.append("\(formatter.string(from: Date())) — \(message)")
        events = Array(events.suffix(20))
    }

    func snapshot() -> String {
        return events.isEmpty ? "No support events recorded" : events.joined(separator: "\n")
    }
}

struct AstronovaSupportReporter: DiagnosticsReporting {
    func report() async -> DiagnosticsChapter {
        let events = await DiagnosticsSupportLog.shared.snapshot()
        return DiagnosticsChapter(
            title: "Privacy-Safe Support Events",
            diagnostics: [
                "Events": events,
                "Collection policy": "Allowlisted lifecycle and report events only; no profile, birth, auth, network payload, or user-default values."
            ]
        )
    }
}
