import Foundation

/// Interface for app settings when the app is in logged out state.
protocol LoggedOutAppSettings {
    var hasInteractedWithOnboarding: Bool { get }
    func setHasInteractedWithOnboarding(_ hasInteractedWithOnboarding: Bool)
}

extension UserDefaults: LoggedOutAppSettings {
    func setHasInteractedWithOnboarding(_ hasInteractedWithOnboarding: Bool) {
        set(hasInteractedWithOnboarding, forKey: .hasInteractedWithOnboarding)
    }

    var hasInteractedWithOnboarding: Bool {
        object(forKey: .hasInteractedWithOnboarding) ?? false
    }
}
