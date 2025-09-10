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
                    Button("See my insights") {
                        Analytics.shared.track(.onboardingCompleted, properties: nil)
                        onComplete?()
                    }
                    .buttonStyle(.borderedProminent)
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

