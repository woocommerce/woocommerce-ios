import Foundation


/// Provides global depedencies.
///
final class ServiceLocator {
    private static var _analytics: Analytics = WooAnalytics(analyticsProvider: TracksProvider())
    private static var _stores: Stores = StoresManager(sessionManager: .standard)

    /// Provides the access point to the analytics.
    /// - Returns: An iumplementation of the Analytics protocol. It defaults to WooAnalytics
    static var analytics: Analytics {
        return _analytics
    }

    /// Provides the access point to the stores.
    /// - Returns: An iumplementation of the Stores protocol. It defaults to StoresManager
    static var stores: Stores {
        return _stores
    }
}


// MARK: - Testability

/// The setters declared in this extension are meant to be used only from the test bundle
extension ServiceLocator {
    static func setAnalytics(_ mock: Analytics) {
        _analytics = mock
    }

    static func setStores(_ mock: Stores) {
        _stores = mock
    }
}
