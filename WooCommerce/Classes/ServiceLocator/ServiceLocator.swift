import Foundation


/// Provides global depedencies.
///
final class ServiceLocator {
    private static var _analytics: Analytics = WooAnalytics(analyticsProvider: TracksProvider())

    /// Provides the access point to the analytics.
    /// - Returns: An iumplementation of the Analytics protocol. It defaults to WooAnalytics
    static var analytics: Analytics {
        return _analytics
    }
}


// MARK: - Testability

/// The setters declared in this extension are meant to be used only from the test bundle
extension ServiceLocator {
    static func setAnalytics(_ mock: Analytics) {
        _analytics = mock
    }
}
