import Storage
import Yosemite
@testable import WooCommerce

/// MockupAvailabilityStoreManager: allows mocking for stats v4 availability and last shown stats version.
///
class MockupStatsVersionStoresManager: DefaultStoresManager {

    /// Indicates if stats v4 is available.
    ///
    var isStatsV4Available = false

    /// Indicates whether the v3 to v4 banner should be shown.
    ///
    var shouldShowV3ToV4Banner: Bool = true

    /// Indicates whether the v4 to v3 banner should be shown.
    ///
    var shouldShowV4ToV3Banner: Bool = true

    /// Set by setter `AppSettingsAction`.
    ///
    var statsVersionLastShown: StatsVersion?

    init(initialStatsVersionLastShown: StatsVersion? = nil, sessionManager: SessionManager) {
        self.statsVersionLastShown = initialStatsVersionLastShown
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let availabilityAction = action as? AvailabilityAction {
            onAvailabilityAction(action: availabilityAction)
        } else if let appSettingsAction = action as? AppSettingsAction {
            onAppSettingsAction(action: appSettingsAction)
        } else {
            super.dispatch(action)
        }
    }

    private func onAvailabilityAction(action: AvailabilityAction) {
        switch action {
        case .checkStatsV4Availability(_,
                                       let onCompletion):
            onCompletion(isStatsV4Available)
        }
    }

    private func onAppSettingsAction(action: AppSettingsAction) {
        switch action {
        case .loadInitialStatsVersionToShow(_, let onCompletion):
            onCompletion(statsVersionLastShown)
        case .loadStatsVersionBannerVisibility(let banner, let onCompletion):
            switch banner {
            case .v3ToV4:
                onCompletion(shouldShowV3ToV4Banner)
            case .v4ToV3:
                onCompletion(shouldShowV4ToV3Banner)
            }
        case .setStatsVersionBannerVisibility(let banner, let shouldShowBanner):
            switch banner {
            case .v3ToV4:
                shouldShowV3ToV4Banner = shouldShowBanner
            case .v4ToV3:
                shouldShowV4ToV3Banner = shouldShowBanner
            }
        case .setStatsVersionLastShown(_, let statsVersion):
            statsVersionLastShown = statsVersion
        default:
            return
        }
    }
}
