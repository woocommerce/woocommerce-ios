import Foundation

protocol AnalyticsConsentProviding: AnyObject {
    var userHasOptedIn: Bool { get set }
}

/// Persists the device's analytics preference independently of the logged-in session.
final class UserDefaultsAnalyticsConsent: AnalyticsConsentProviding {
    private let userDefaults: UserDefaults
    private let isUITesting: Bool

    init(userDefaults: UserDefaults = .standard,
         isUITesting: Bool = CommandLine.arguments.contains("-ui_testing")) {
        self.userDefaults = userDefaults
        self.isUITesting = isUITesting
    }

    var userHasOptedIn: Bool {
        get {
            let optedIn: Bool? = userDefaults.object(forKey: .userOptedInAnalytics)
            return (optedIn ?? true) && !isUITesting
        }
        set {
            userDefaults.set(newValue, forKey: .userOptedInAnalytics)
        }
    }
}
