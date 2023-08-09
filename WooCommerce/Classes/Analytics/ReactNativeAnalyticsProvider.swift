import Foundation
// import protocol WooCommerceShared.WCRNAnalyticsProvider

/// Class that provides an interface to `ReactNative` to log track events using the main app `analyticsProvider`.
///
final class ReactNativeAnalyticsProvider /*: WCRNAnalyticsProvider*/ {

    /// Sends an event using `ServiceLocator.analyticsProvider`.
    ///
    func sendEvent(_ event: String) {
        ServiceLocator.analytics.analyticsProvider.track(event)
    }
}
