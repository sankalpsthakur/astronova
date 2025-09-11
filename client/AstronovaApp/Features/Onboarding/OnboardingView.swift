import SwiftUI

struct OnboardingView: View {
    @State private var fullName = ""
    @State private var birthDate = Date()
    @State private var birthTime = Date()
    @State private var birthPlace = ""

    var onComplete: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section("Your Details") {
                    TextField("Full name", text: $fullName)
                    DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                    BirthTimePicker(time: $birthTime)
                    TextField("Birth place", text: $birthPlace)
                }
                Section {
                    Button("See my free insight") {
                        Analytics.shared.track(.onboardingCompleted, properties: nil)
                        onComplete?()
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        // Jump to Today tab and open Reports shop from there
                        NotificationCenter.default.post(name: .switchToTab, object: 0)
                    } label: {
                        Label("Skip to detailed reports (from $12.99)", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Create Profile")
            .onAppear { Analytics.shared.track(.onboardingViewed, properties: nil) }
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif
