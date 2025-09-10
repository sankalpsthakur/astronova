import SwiftUI

/// Reusable birth time picker with an "I don't know" toggle and explanation.
struct BirthTimePicker: View {
    @Binding var time: Date
    @State private var isUnknown: Bool
    @State private var showWhy = false

    init(time: Binding<Date>, isUnknown: Bool = false) {
        self._time = time
        self._isUnknown = State(initialValue: isUnknown)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Toggle(isOn: $isUnknown) {
                    Text("I don't know my birth time")
                        .font(.body)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))

                Button(action: { showWhy = true }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Why is birth time important?")
                .alert("Why birth time matters", isPresented: $showWhy) {
                    Button("Got it", role: .cancel) {}
                } message: {
                    Text("Birth time improves rising sign and house calculations. If unknown, we'll assume 12:00 noon and note that some insights may be approximate.")
                }
            }

            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .disabled(isUnknown)
            .opacity(isUnknown ? 0.5 : 1.0)
        }
    }
}

#if DEBUG
struct BirthTimePicker_Previews: PreviewProvider {
    static var previews: some View {
        BirthTimePicker(time: .constant(Date()))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

