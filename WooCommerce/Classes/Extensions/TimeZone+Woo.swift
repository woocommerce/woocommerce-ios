import Foundation


/// TimeZone: Constant Helpers
///
extension TimeZone {

    /// Returns the TimeZone using the timezone configured in the current website
    ///
    static var websiteTimezone: TimeZone {
        guard let gmtOffset = ServiceLocator.stores.sessionManager.defaultSite?.gmtOffset else {
            return .current
        }
        let secondsFromGMT = Int(gmtOffset * 3600)
        return TimeZone(secondsFromGMT: secondsFromGMT) ?? .current
    }
}
