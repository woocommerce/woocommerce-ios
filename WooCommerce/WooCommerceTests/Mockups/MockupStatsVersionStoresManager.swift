import Storage
import Yosemite
@testable import WooCommerce

/// MockupAvailabilityStoreManager: allows mocking for stats v4 availability and last shown stats version.
///
class MockupStatsVersionStoresManager: DefaultStoresManager {

    /// Indicates if stats v4 is available.
    ///
    var isStatsV4Available = false

    /// Set by setter `AppSettingsAction`.
    ///
    private var statsVersionLastShown: StatsVersion?

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
        case .loadStatsVersionLastShown(_, let onCompletion):
            onCompletion(statsVersionLastShown)
        case .setStatsVersionLastShown(_, let statsVersion):
            statsVersionLastShown = statsVersion
        default:
            return
        }
    }
}
