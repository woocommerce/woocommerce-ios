// MARK: - StatsV4AvailabilityAction: Defines actions regarding Stats v4 availability.
//
public enum StatsV4AvailabilityAction: Action {
    /// Checks if Stats v4 is available for the site.
    ///
    case checkStatsV4Availability(siteID: Int, onCompletion: (_ isStatsV4Available: Bool) -> Void)
}
