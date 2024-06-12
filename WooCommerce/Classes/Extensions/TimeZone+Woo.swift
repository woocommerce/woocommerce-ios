import Foundation


/// TimeZone: Constant Helpers
///
extension TimeZone {

    /// Returns the TimeZone using the timezone configured in the current website
    ///
    static var siteTimezone: TimeZone {
#if !os(watchOS)
        return ServiceLocator.stores.sessionManager.defaultSite?.siteTimezone ?? .current
#else
        return .current // WatchOS currently does not have a notion of ServiceLocator or the current site timezone
#endif
    }
}
