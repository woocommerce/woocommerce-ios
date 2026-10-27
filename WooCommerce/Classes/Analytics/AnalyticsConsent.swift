import Foundation
import os

protocol AnalyticsConsentProviding: AnyObject, Sendable {
    var userHasOptedIn: Bool { get set }
}

/// Persists the device's analytics preference independently of the logged-in session.
final class UserDefaultsAnalyticsConsent: AnalyticsConsentProviding {
    /// `UserDefaults` is documented as thread-safe but does not declare `Sendable`.
    private let userDefaults: OSAllocatedUnfairLock<UserDefaults>
    private let isUITesting: Bool

    init(userDefaults: UserDefaults = .standard,
         isUITesting: Bool = CommandLine.arguments.contains("-ui_testing")) {
        self.userDefaults = OSAllocatedUnfairLock(uncheckedState: userDefaults)
        self.isUITesting = isUITesting
    }

    var userHasOptedIn: Bool {
        get {
            let optedIn: Bool? = userDefaults.withLockUnchecked {
                $0.object(forKey: .userOptedInAnalytics)
            }
            return (optedIn ?? true) && !isUITesting
        }
        set {
            userDefaults.withLockUnchecked {
                $0.set(newValue, forKey: .userOptedInAnalytics)
            }
        }
    }
}
