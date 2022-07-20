import Foundation

/// Interface for app settings when the app is in logged out state.
protocol LoggedOutAppSettings {
    var hasFinishedOnboarding: Bool { get }
    func setHasFinishedOnboarding(_ hasFinishedOnboarding: Bool)
}

extension UserDefaults: LoggedOutAppSettings {
    var hasFinishedOnboarding: Bool {
        object(forKey: .hasFinishedOnboarding) ?? false
    }

    func setHasFinishedOnboarding(_ hasFinishedOnboarding: Bool) {
        set(hasFinishedOnboarding, forKey: .hasFinishedOnboarding)
    }
}
