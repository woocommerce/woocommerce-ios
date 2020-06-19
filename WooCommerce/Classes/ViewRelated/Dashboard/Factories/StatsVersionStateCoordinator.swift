import Storage
import Yosemite

/// Reflects the UI state associated with a stats version.
///
/// - initial: UI with the initial stats version from preferences in storage
/// - eligible: when reaching an eligible stats version without any other potential state changes
/// - v3ShownV4Eligible: when v3 is currently shown, and the site is also eligible for v4
/// - v4RevertedToV3: when v4 is currently shown, and the UI is reverted to v3
enum StatsVersionState {
    case initial(statsVersion: StatsVersion)
    case eligible(statsVersion: StatsVersion)
    case v3ShownV4Eligible
    case v4RevertedToV3
}

extension StatsVersionState: Equatable {
    static func == (lhs: StatsVersionState, rhs: StatsVersionState) -> Bool {
        switch (lhs, rhs) {
        case let (.initial(lhsStatsVersion), .initial(rhsStatsVersion)):
            return lhsStatsVersion == rhsStatsVersion
        case let (.eligible(lhsStatsVersion), .eligible(rhsStatsVersion)):
            return lhsStatsVersion == rhsStatsVersion
        case (.v3ShownV4Eligible, .v3ShownV4Eligible):
            return true
        case (.v4RevertedToV3, .v4RevertedToV3):
            return true
        default:
            return false
        }
    }
}

/// Coordinates the stats version state changes from app settings and availability stores, and v3/v4 banner actions.
///
final class StatsVersionStateCoordinator {
    typealias StateChangeCallback = (_ previousState: StatsVersionState?, _ currentState: StatsVersionState) -> Void
    /// Called when stats version UI state is set.
    var onStateChange: StateChangeCallback?

    private let siteID: Int64

    private var state: StatsVersionState? {
        didSet {
            if let state = state {
                onStateChange?(oldValue, state)
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
            let state = StatsVersionState.initial(statsVersion: lastStatsVersion)
            self.state = state

            // Execute network request to check if the API supports the V4 stats
            let action = AvailabilityAction.checkStatsV4Availability(siteID: self.siteID) { [weak self] isStatsV4Available in
                guard let self = self else {
                    return
                }
                let statsVersion: StatsVersion = isStatsV4Available ? .v4: .v3

                // Sets eligible stats version to app settings.
                let setEligibleStatsVersionAction = AppSettingsAction.setStatsVersionEligible(siteID: self.siteID, statsVersion: statsVersion)
                ServiceLocator.stores.dispatch(setEligibleStatsVersionAction)

                let nextState = StatsVersionState.initial(statsVersion: statsVersion)
                if nextState != self.state {
                    self.state = nextState
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
        ServiceLocator.stores.dispatch(lastShownStatsVersionAction)
    }
}

extension StatsVersionStateCoordinator: StatsV3ToV4BannerActionHandler {
    func dismissV3ToV4Banner() {
        let visibilityAction = AppSettingsAction.setStatsVersionBannerVisibility(banner: .v3ToV4, shouldShowBanner: false)
        ServiceLocator.stores.dispatch(visibilityAction)
        state = .eligible(statsVersion: .v3)
    }

    func statsV4ButtonPressed() {
        state = .eligible(statsVersion: .v4)
    }
}

extension StatsVersionStateCoordinator: StatsV4ToV3BannerActionHandler {
    func dismissV4ToV3Banner() {
        let visibilityAction = AppSettingsAction.setStatsVersionBannerVisibility(banner: .v4ToV3, shouldShowBanner: false)
        ServiceLocator.stores.dispatch(visibilityAction)
        state = .eligible(statsVersion: .v3)
    }
}
