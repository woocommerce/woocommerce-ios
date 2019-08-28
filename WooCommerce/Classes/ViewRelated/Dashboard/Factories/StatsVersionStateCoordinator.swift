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
    private let siteID: Int
    private let onStateChange: (_ state: StatsVersionState) -> Void

    private var state: StatsVersionState? {
        didSet {
            if let state = state, state != oldValue {
                onStateChange(state)
            }
        }
    }

    /// Initializes `StatsVersionStateCoordinator` for a site ID.
    ///
    /// - Notable parameters:
    ///   - siteID: the ID of a site/store where the stats version is concerned.
    ///   - onStateChange: called when stats version state changes.
    init(siteID: Int,
         onStateChange: @escaping (_ state: StatsVersionState) -> Void) {
        self.siteID = siteID
        self.onStateChange = onStateChange
    }

    func loadLastShownVersionAndCheckV4Eligibility() {
        let lastShownStatsVersionAction = AppSettingsAction.loadStatsVersionLastShown(siteID: siteID) { [weak self] lastShownStatsVersion in
            let lastStatsVersion: StatsVersion = lastShownStatsVersion ?? StatsVersion.v3
            self?.state = .initial(statsVersion: lastStatsVersion)

            guard let siteID = self?.siteID else {
                return
            }
            let action = AvailabilityAction.checkStatsV4Availability(siteID: siteID) { [weak self] isStatsV4Available in
                let statsVersion: StatsVersion = isStatsV4Available ? .v4: .v3
                self?.updateState(eligibleStatsVersion: statsVersion)
            }
            ServiceLocator.stores.dispatch(action)
        }
        ServiceLocator.stores.dispatch(lastShownStatsVersionAction)
    }

    /// Called when eligible stats version is set.
    private func updateState(eligibleStatsVersion: StatsVersion) {
        guard let state = state else {
            self.state = .eligible(statsVersion: eligibleStatsVersion)
            return
        }
        switch state {
        case .initial(let initialStatsVersion):
            guard initialStatsVersion != eligibleStatsVersion else {
                self.state = .eligible(statsVersion: eligibleStatsVersion)
                return
            }
            switch initialStatsVersion {
            case .v3:
                // V3 to V4
                self.state = .v3ShownV4Eligible
            case .v4:
                // V4 to V3
                self.state = .v4RevertedToV3
            }
        default:
            return
        }
    }
}

extension StatsVersionStateCoordinator: StatsV3ToV4BannerActionHandler {
    func dismissV3ToV4Banner() {
        state = .eligible(statsVersion: .v3)
    }

    func statsV4ButtonPressed() {
        state = .eligible(statsVersion: .v4)
    }
}

extension StatsVersionStateCoordinator: StatsV4ToV3BannerActionHandler {
    func dismissV4ToV3Banner() {
        state = .eligible(statsVersion: .v3)
    }
}
