//
//  VideoSessionWebView.swift
//  AstronovaApp
//
//  Twilio Video Session WebView Integration
//

import SwiftUI
import WebKit

// MARK: - Video Session WebView

struct VideoSessionWebView: View {
    let sessionId: String
    let userName: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicVoid.ignoresSafeArea()

                if let error = loadError {
                    ErrorStateView(error: error) {
                        dismiss()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Loading indicator
                        if isLoading {
                            ProgressView("Connecting to session...")
                                .foregroundColor(.cosmicGold)
                                .padding()
                        }

                        // WebView
                        VideoWebView(
                            sessionId: sessionId,
                            userName: userName,
                            isLoading: $isLoading,
                            loadError: $loadError
                        )
                    }
                }
            }
            .navigationTitle("Pooja Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.cosmicGold)
                    }
                }
            }
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.cosmicCopper)

            Text("Connection Error")
                .font(.cosmicTitle2)
                .foregroundColor(.cosmicTextPrimary)

            Text(error)
                .font(.cosmicBody)
                .foregroundColor(.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onDismiss) {
                Text("Close")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundColor(.cosmicVoid)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient.cosmicAntiqueGold
                    )
                    .clipShape(Capsule())
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

// MARK: - WebView UIViewRepresentable

struct VideoWebView: UIViewRepresentable {
    let sessionId: String
    let userName: String
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Enable inline media playback (critical for video)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Enable camera and microphone access
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false

        // Allow camera/mic permissions
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "messageHandler"
        )

        // Load the session page
        let baseURL = AppConfig.shared.apiBaseURL
        guard let url = URL(string: "\(baseURL)/api/v1/temple/session/\(sessionId)") else {
            DispatchQueue.main.async {
                loadError = "Invalid session URL"
                isLoading = false
            }
            return webView
        }

        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: VideoWebView

        init(_ parent: VideoWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Auto-fill the name input and trigger preview
            let script = """
            (function() {
                // Wait for DOM to be ready
                setTimeout(function() {
                    var nameInput = document.getElementById('nameInput');
                    if (nameInput) {
                        nameInput.value = '\(parent.userName)';

                        // Optionally auto-join after a delay
                        // setTimeout(function() {
                        //     var joinBtn = document.getElementById('joinBtn');
                        //     if (joinBtn) joinBtn.click();
                        // }, 500);
                    }
                }, 500);
            })();
            """

            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("[VideoWebView] JavaScript error: \(error)")
                }
            }

            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.loadError = "Failed to load video session: \(error.localizedDescription)"
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.loadError = "Connection failed. Please check your internet connection."
                self.parent.isLoading = false
            }
        }

        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Handle any messages from the web page if needed
            print("[VideoWebView] Message from web: \(message.body)")
        }

        // Handle permission requests (camera/microphone)
        func webView(
            _ webView: WKWebView,
            decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
            initiatedBy frame: WKFrameInfo,
            type: WKMediaCaptureType
        ) async -> WKPermissionDecision {
            // Grant camera and microphone permissions for:
            // - Our own domain (astronova backend)
            // - meet.jit.si (Jitsi Meet video calls)
            // - 8x8.vc (Jitsi's CDN domain)
            let allowedHosts = ["meet.jit.si", "8x8.vc", "astronova.app", "localhost", "127.0.0.1"]
            let host = origin.host.lowercased()

            if allowedHosts.contains(where: { host.contains($0) }) {
                print("[VideoWebView] Granting \(type == .camera ? "camera" : "microphone") permission for \(host)")
                return .grant
            }

            print("[VideoWebView] Denying media permission for unknown host: \(host)")
            return .deny
        }
    }
}

// MARK: - Preview

#if DEBUG
struct VideoSessionWebView_Previews: PreviewProvider {
    static var previews: some View {
        VideoSessionWebView(
            sessionId: "test-session-123",
            userName: "John Doe"
        )
    }
}
#endif
