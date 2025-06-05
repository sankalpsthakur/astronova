import Foundation
import Combine
import CloudKitKit

/// ViewModel for managing user settings persisted in CloudKit and UserDefaults.
@available(iOS 13.0, *)
public final class SettingsViewModel: ObservableObject {
    @Published public var selectedLanguage: String

    public init(defaultLanguage: String = Locale.current.identifier) {
        self.selectedLanguage = defaultLanguage
    }
}