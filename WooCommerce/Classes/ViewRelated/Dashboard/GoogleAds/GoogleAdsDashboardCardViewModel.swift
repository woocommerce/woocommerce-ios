import Combine
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `GoogleAdsDashboardCard`.
final class GoogleAdsDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let eligibilityChecker: GoogleAdsEligibilityChecker

    var shouldShowErrorState: Bool {
        syncingError != nil
    }

    var shouldShowShowAllCampaignsButton: Bool {
        lastCampaign != nil && syncingError == nil
    }

    var shouldShowCreateCampaignButton: Bool {
        syncingError == nil
    }

    @Published private(set) var canShowOnDashboard = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var syncingData = true
    @Published private(set) var lastCampaign: GoogleAdsCampaign?
    @Published private(set) var lastCampaignStats: GoogleAdsCampaignStatsTotals?

    @Published private var viewAppeared = false

    private var subscriptions: Set<AnyCancellable> = []

    init(siteID: Int64,
         eligibilityChecker: GoogleAdsEligibilityChecker = DefaultGoogleAdsEligibilityChecker(),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.eligibilityChecker = eligibilityChecker
        trackEntryPointDisplayedIfNeeded()
    }

    @MainActor
    func checkAvailability() async {
        canShowOnDashboard = await eligibilityChecker.isSiteEligible(siteID: siteID)
    }

    func dismissCard() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .googleAds))
        onDismiss?()
    }

    @MainActor
    func fetchLastCampaign() async {
        syncingError = nil
        syncingData = true
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .googleAds))
        do {
            let campaigns = try await fetchAdsCampaigns()
            lastCampaign = {
                // prioritize showing last enabled campaign.
                let enabledCampaigns = campaigns.filter { $0.status == .enabled }
                return enabledCampaigns.last ?? campaigns.last
            }()

            /// Updates the UI immediately after getting last campaign details
            syncingData = false

            /// Fetches stats for the last campaign
            if let id = lastCampaign?.id {
                lastCampaignStats = await retrieveLastCampaignStats(campaignID: id)
            }

            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .googleAds))
        } catch {
            syncingError = error
            syncingData = false
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .googleAds, error: error))
            DDLogError("⛔️ Error loading Google ads campaigns: \(error)")
        }
    }

    func onViewAppear() {
        viewAppeared = true
    }
}

private extension GoogleAdsDashboardCardViewModel {

    func trackEntryPointDisplayedIfNeeded() {
        $canShowOnDashboard.removeDuplicates()
            .combineLatest($syncingData.removeDuplicates(), $viewAppeared)
            .filter { canShow, syncingData, viewAppeared in
                return canShow && !syncingData && viewAppeared
            }
            .sink { [weak self] _ in
                guard let self else { return }
                analytics.track(event: .GoogleAds.entryPointDisplayed(source: .myStore))
            }
            .store(in: &subscriptions)
    }

    @MainActor
    func fetchAdsCampaigns() async throws -> [GoogleAdsCampaign] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(GoogleAdsAction.fetchAdsCampaigns(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func retrieveLastCampaignStats(campaignID: Int64) async -> GoogleAdsCampaignStatsTotals? {
        do {
            let stats = try await retrieveCampaignStats(campaignID: campaignID)
            guard stats.campaigns.isNotEmpty else {
                return stats.totals
            }
            return stats.campaigns.first(where: { $0.id == campaignID })?.subtotals
        } catch {
            DDLogError("⛔️ Error retrieving Google ads campaign stats: \(error)")
            return nil
        }
    }

    @MainActor
    func retrieveCampaignStats(campaignID: Int64) async throws -> GoogleAdsCampaignStats {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(GoogleAdsAction.retrieveCampaignStats(
                siteID: siteID,
                campaignIDs: [campaignID],
                timeZone: TimeZone.siteTimezone,
                earliestDateToInclude: Date(),
                latestDateToInclude: Date.distantPast) { result in
                    continuation.resume(with: result)
                }
            )
        }
    }
}
