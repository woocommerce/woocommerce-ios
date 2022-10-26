import Yosemite
import enum Networking.DotcomError
import enum Storage.StatsVersion

/// Syncs data for dashboard stats UI and determines the state of the dashboard UI based on stats version.
final class DashboardViewModel {
    /// Stats v4 is shown by default, then falls back to v3 if store stats are unavailable.
    @Published private(set) var statsVersion: StatsVersion = .v4

    @Published private(set) var announcementViewModel: AnnouncementCardViewModelProtocol? = nil

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// Syncs store stats for dashboard UI.
    func syncStats(for siteID: Int64,
                   siteTimezone: TimeZone,
                   timeRange: StatsTimeRangeV4,
                   latestDateToInclude: Date,
                   forceRefresh: Bool,
                   onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardMainStats)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveStats(siteID: siteID,
                                                 timeRange: timeRange,
                                                 earliestDateToInclude: earliestDateToInclude,
                                                 latestDateToInclude: latestDateToInclude,
                                                 quantity: timeRange.maxNumberOfIntervals,
                                                 forceRefresh: forceRefresh,
                                                 onCompletion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                waitingTracker.end()
                self.statsVersion = .v4
            case .failure(let error):
                DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats v4: \(error)")
                if error as? DotcomError == .noRestRoute {
                    self.statsVersion = .v3
                } else {
                    self.statsVersion = .v4
                }
            }
            onCompletion?(result)
        })
        stores.dispatch(action)
    }

    /// Syncs visitor stats for dashboard UI.
    func syncSiteVisitStats(for siteID: Int64,
                            siteTimezone: TimeZone,
                            timeRange: StatsTimeRangeV4,
                            latestDateToInclude: Date,
                            onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let action = StatsActionV4.retrieveSiteVisitStats(siteID: siteID,
                                                          siteTimezone: siteTimezone,
                                                          timeRange: timeRange,
                                                          latestDateToInclude: latestDateToInclude,
                                                          onCompletion: { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
            }
            onCompletion?(result)
        })
        stores.dispatch(action)
    }

    /// Syncs top performers data for dashboard UI.
    func syncTopEarnersStats(for siteID: Int64,
                             siteTimezone: TimeZone,
                             timeRange: StatsTimeRangeV4,
                             latestDateToInclude: Date,
                             forceRefresh: Bool,
                             onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardTopPerformers)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                          timeRange: timeRange,
                                                          earliestDateToInclude: earliestDateToInclude,
                                                          latestDateToInclude: latestDateToInclude,
                                                          quantity: Constants.topEarnerStatsLimit,
                                                          forceRefresh: forceRefresh,
                                                          onCompletion: { result in
            switch result {
            case .success:
                waitingTracker.end()
                ServiceLocator.analytics.track(event:
                        .Dashboard.dashboardTopPerformersLoaded(timeRange: timeRange))
            case .failure(let error):
                DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
            }
            onCompletion?(result)
        })
        stores.dispatch(action)
    }

    /// Checks for announcements to show on the dashboard
    ///
    func syncAnnouncements(for siteID: Int64) {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.justInTimeMessagesOnDashboard) {
            let action = JustInTimeMessageAction.loadMessage(
                siteID: siteID,
                screen: Constants.dashboardScreenName,
                hook: .adminNotices) { result in
                    switch result {
                    case let .success(.some(message)):
                        let viewModel = JustInTimeMessageAnnouncementCardViewModel(title: message.title,
                                                                                   message: message.detail,
                                                                                   buttonTitle: message.buttonTitle)
                        self.announcementViewModel = viewModel
                    default:
                        break
                    }
                }
            stores.dispatch(action)
        }
    }
}

// MARK: - Constants
//
private extension DashboardViewModel {
    enum Constants {
        static let topEarnerStatsLimit: Int = 5
        static let dashboardScreenName = "my_store"
    }
}
