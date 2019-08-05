import Foundation
import Networking

// MARK: - StatsActionV4: Defines stats operations (supported by the StatsStoreV4).
//
public enum StatsActionV4: Action {

    /// Clears all of the stats data.
    ///
    case resetStoredStats(onCompletion: () -> Void)

    /// Synchronizes `OrderStats` for the provided siteID, StatGranularity, and date.
    ///
    case retrieveStats(siteID: Int,
        granularity: StatsGranularityV4,
        earliestDateToInclude: Date,
        latestDateToInclude: Date,
        quantity: Int,
        onCompletion: (Error?) -> Void)
}
