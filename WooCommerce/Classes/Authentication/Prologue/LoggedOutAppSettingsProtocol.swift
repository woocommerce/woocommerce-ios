import Foundation

/// Interface for app settings when the app is in logged out state.
protocol LoggedOutAppSettingsProtocol {
    var hasFinishedOnboarding: Bool { get }
    func setHasFinishedOnboarding(_ hasFinishedOnboarding: Bool)

    var errorLoginSiteAddress: String? { get }
    func setErrorLoginSiteAddress(_ address: String)
}

/// UserDefaults based settings when the app is in logged out state.
/// When the user is logged out, `StoresManager` uses `DeauthenticatedState` which does not handle any actions.
final class LoggedOutAppSettings {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}

extension LoggedOutAppSettings: LoggedOutAppSettingsProtocol {
    var hasFinishedOnboarding: Bool {
        userDefaults.object(forKey: .hasFinishedOnboarding) ?? false
    }

    func setHasFinishedOnboarding(_ hasFinishedOnboarding: Bool) {
        userDefaults.set(hasFinishedOnboarding, forKey: .hasFinishedOnboarding)
    }

    var errorLoginSiteAddress: String? {
        userDefaults.object(forKey: .errorLoginSiteAddress)
    }

    func setErrorLoginSiteAddress(_ address: String) {
        userDefaults.set(address, forKey: .errorLoginSiteAddress)
    }
}
