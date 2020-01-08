import Foundation


/// TimeZone: Constant Helpers
///
extension TimeZone {

    /// Returns the TimeZone using the timezone configured in the current website
    ///
    static var websiteTimezone: TimeZone {
        return ServiceLocator.stores.sessionManager.defaultSite?.siteTimezone ?? .current
    }
}
