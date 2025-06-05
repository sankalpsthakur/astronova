import SwiftUI

/// Simple view for chats; currently lists no conversations.
struct ChatView: View {
    var body: some View {
        NavigationView {
            Text("No messages yet")
                .foregroundStyle(.secondary)
                .navigationTitle("Chat")
        }
    }
}

#if DEBUG
#Preview {
    ChatView()
}
#endif
