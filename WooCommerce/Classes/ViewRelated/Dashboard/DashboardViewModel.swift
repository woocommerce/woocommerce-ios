import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Experiments.FeatureFlagService

/// Syncs data for dashboard stats UI and determines the state of the dashboard UI based on stats version.
final class DashboardViewModel {
    /// Stats v4 is shown by default, then falls back to v3 if store stats are unavailable.
    @Published private(set) var statsVersion: StatsVersion = .v4

    @Published var announcementViewModel: AnnouncementCardViewModelProtocol? = nil

    @Published private(set) var showWebViewSheet: WebViewSheetViewModel? = nil

    /// Trigger to start the Add Product flow
    ///
    let addProductTrigger = PassthroughSubject<Void, Never>()

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.featureFlagService = featureFlags
        self.analytics = analytics
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
        syncProductsOnboarding(for: siteID) { [weak self] in
            self?.syncJustInTimeMessages(for: siteID)
        }
    }

    /// Checks if a store is eligible for products onboarding and prepares the onboarding announcement if needed.
    ///
    private func syncProductsOnboarding(for siteID: Int64, onCompletion: @escaping () -> Void) {
        let action = ProductAction.checkProductsOnboardingEligibility(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let isEligible):
                if isEligible {
                    ServiceLocator.analytics.track(event: .ProductsOnboarding.storeIsEligible())

                    self?.setProductsOnboardingBannerIfNeeded()
                }

                // For now, products onboarding takes precedence over Just In Time Messages,
                // so we can stop if there is an onboarding announcement to display.
                // This should be revisited when either onboarding or JITMs are expanded. See: pe5pgL-11B-p2
                if self?.announcementViewModel is ProductsOnboardingAnnouncementCardViewModel {
                    return
                }
                onCompletion()
            case .failure(let error):
                DDLogError("⛔️ Dashboard — Error checking products onboarding eligibility: \(error)")
                onCompletion()
            }
        }
        stores.dispatch(action)
    }

    /// Sets the view model for the products onboarding banner if the user hasn't dismissed it before.
    ///
    private func setProductsOnboardingBannerIfNeeded() {
        let getVisibility = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .productsOnboarding) { [weak self] result in
            guard let self else { return }
            if case let .success(isVisible) = result, isVisible {
                let viewModel = ProductsOnboardingAnnouncementCardViewModel(onCTATapped: { [weak self] in
                    self?.addProductTrigger.send()
                })
                self.announcementViewModel = viewModel
            }
        }
        stores.dispatch(getVisibility)
    }

    /// Checks for Just In Time Messages and prepares the announcement if needed.
    ///
    private func syncJustInTimeMessages(for siteID: Int64) {
        guard featureFlagService.isFeatureFlagEnabled(.justInTimeMessagesOnDashboard) else {
            return
        }

        let action = JustInTimeMessageAction.loadMessage(
            siteID: siteID,
            screen: Constants.dashboardScreenName,
            hook: .adminNotices) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(messages):
                    guard let message = messages.first else {
                        self.announcementViewModel = nil
                        return
                    }
                    self.analytics.track(event:
                            .JustInTimeMessage.fetchSuccess(source: Constants.dashboardScreenName,
                                                            messageID: message.messageID,
                                                            count: Int64(messages.count)))
                    let viewModel = JustInTimeMessageAnnouncementCardViewModel(
                        justInTimeMessage: message,
                        screenName: Constants.dashboardScreenName,
                        siteID: siteID)
                    self.announcementViewModel = viewModel
                    viewModel.$showWebViewSheet.assign(to: &self.$showWebViewSheet)
                case let .failure(error):
                    self.analytics.track(event:
                            .JustInTimeMessage.fetchFailure(source: Constants.dashboardScreenName,
                                                            error: error))
                }
            }
        stores.dispatch(action)
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
