import Foundation


/// TimeZone: Constant Helpers
///
extension TimeZone {

    /// Returns the TimeZone using the timezone configured in the current website
    ///
    static var siteTimezone: TimeZone {
        return ServiceLocator.stores.sessionManager.defaultSite?.siteTimezone ?? .current
    }
}
