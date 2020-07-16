import Storage
import Yosemite

/// Coordinates the stats version changes from app settings and availability stores, and v3/v4 banner actions.
///
final class StatsVersionStateCoordinator {
    typealias VersionChangeCallback = (_ previousVersion: StatsVersion?, _ currentVersion: StatsVersion) -> Void

    /// Called when stats version has changed.
    var onVersionChange: VersionChangeCallback?

    private let siteID: Int64

    private var version: StatsVersion? {
        didSet {
            if let state = version {
                onVersionChange?(oldValue, state)
            }
        }
    }

    /// Initializes `StatsVersionStateCoordinator` for a site ID.
    ///
    /// - Parameters:
    ///   - siteID: the ID of a site/store where the stats version is concerned.
    init(siteID: Int64) {
        self.siteID = siteID
    }

    func loadLastShownVersionAndCheckV4Eligibility() {
        // Load saved stats version from app settings
        let lastShownStatsVersionAction = AppSettingsAction.loadInitialStatsVersionToShow(siteID: siteID) { [weak self] initialStatsVersion in
            guard let self = self else {
                return
            }

            let lastStatsVersion: StatsVersion = initialStatsVersion ?? StatsVersion.v3
            self.version = lastStatsVersion

            // Execute network request to check if the API supports the V4 stats
            let action = AvailabilityAction.checkStatsV4Availability(siteID: self.siteID) { [weak self] isStatsV4Available in
                guard let self = self else {
                    return
                }
                let nextVersion: StatsVersion = isStatsV4Available ? .v4: .v3
                if nextVersion != self.version {
                    self.version = nextVersion
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
        ServiceLocator.stores.dispatch(lastShownStatsVersionAction)
    }
}
