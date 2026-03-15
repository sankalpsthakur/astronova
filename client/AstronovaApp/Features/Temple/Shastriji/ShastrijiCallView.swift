import SwiftUI
import WebKit

// MARK: - Jitsi WebView (UIViewRepresentable)

/// WKWebView wrapper configured for Jitsi Meet video calls.
/// Enables inline media playback and auto-play so the call connects without
/// requiring additional user interaction inside the web view.
struct JitsiWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Shastriji Call View

/// Full-screen video call interface for Shastriji consultations.
///
/// Present this view as a `.fullScreenCover` when a booking reaches the
/// "connected" call state. The parent supplies the Jitsi Meet URL generated
/// by the backend (`https://meet.jit.si/astronova-{session_id}`) and an
/// `onEndCall` closure that should PATCH the call-state to "ended".
struct ShastrijiCallView: View {

    // MARK: - Parameters

    let sessionURL: String
    let bookingId: String
    let onEndCall: () -> Void

    // MARK: - State

    @State private var elapsedSeconds: Int = 0
    @State private var showEndCallAlert = false

    /// Timer that fires every second to update the call duration display.
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.cosmicVoid
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                webViewArea
                bottomBar
            }
        }
        .alert("End consultation?", isPresented: $showEndCallAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Call", role: .destructive) {
                onEndCall()
            }
        } message: {
            Text("This will end your Shastriji consultation session.")
        }
        .onReceive(timer) { _ in
            elapsedSeconds += 1
        }
        .statusBarHidden(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Title
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text("Shastriji Consultation")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                // Duration timer
                Text(formattedDuration)
                    .font(.cosmicMono)
                    .foregroundStyle(Color.cosmicGold)
            }

            Spacer()

            // Dismiss / minimize button
            Button {
                showEndCallAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .accessibleIconButton()
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.vertical, Cosmic.Spacing.sm)
        .background(
            Color.cosmicVoid.opacity(Cosmic.Opacity.dense)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - WebView Area

    private var webViewArea: some View {
        Group {
            if let url = URL(string: sessionURL) {
                JitsiWebView(url: url)
            } else {
                // Fallback when the URL is malformed
                VStack(spacing: Cosmic.Spacing.md) {
                    Image(systemName: "video.slash")
                        .font(.system(size: Cosmic.IconSize.xl))
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text("Unable to load video call")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            Button {
                showEndCallAlert = true
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "phone.down.fill")
                    Text("End Call")
                }
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(.white)
                .frame(height: Cosmic.ButtonHeight.medium)
                .padding(.horizontal, Cosmic.Spacing.xl)
                .background(Color.cosmicError)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, Cosmic.Spacing.md)
        .padding(.bottom, Cosmic.Spacing.xs)
        .frame(maxWidth: .infinity)
        .background(
            Color.cosmicVoid.opacity(Cosmic.Opacity.dense)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Helpers

    /// Formats elapsed seconds as MM:SS.
    private var formattedDuration: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Shastriji Call") {
    ShastrijiCallView(
        sessionURL: "https://meet.jit.si/astronova-preview-session",
        bookingId: "preview-123",
        onEndCall: {}
    )
}
