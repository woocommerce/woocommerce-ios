// MARK: - AvailabilityAction: Defines actions regarding service/feature availability.
//
public enum AvailabilityAction: Action {
    /// Checks if Stats v4 is available for the site.
    ///
    case checkStatsV4Availability(siteID: Int64, onCompletion: (_ isStatsV4Available: Bool) -> Void)
}
