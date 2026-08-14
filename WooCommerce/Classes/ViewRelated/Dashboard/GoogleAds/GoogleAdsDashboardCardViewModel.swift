import Combine
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `GoogleAdsDashboardCard`.
@MainActor
final class GoogleAdsDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let eligibilityChecker: GoogleAdsEligibilityChecker
    private let timeZone: TimeZone

    var shouldShowErrorState: Bool {
        syncingError != nil
    }

    var shouldShowShowAllCampaignsButton: Bool {
        hasPaidCampaigns && syncingError == nil
    }

    var shouldShowCreateCampaignButton: Bool {
        syncingError == nil
    }

    @Published private(set) var canShowOnDashboard = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var syncingData = true

    @Published private(set) var hasPaidCampaigns = false
    @Published private(set) var performanceStats: GoogleAdsCampaignStatsTotals?

    @Published private var viewAppeared = false

    private var subscriptions: Set<AnyCancellable> = []

    init(siteID: Int64,
         eligibilityChecker: GoogleAdsEligibilityChecker = DefaultGoogleAdsEligibilityChecker(),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         timeZone: TimeZone = .siteTimezone) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.eligibilityChecker = eligibilityChecker
        self.timeZone = timeZone
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
    func reloadCard() async {
        syncingError = nil
        syncingData = true
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .googleAds))
        do {
            let campaigns = try await fetchAdsCampaigns()
            hasPaidCampaigns = campaigns.isNotEmpty

            /// Fetches total performance stats
            if hasPaidCampaigns {
                let stats = try await retrieveCampaignStats()
                performanceStats = stats.totals
            } else {
                performanceStats = nil
            }

            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .googleAds))
        } catch {
            syncingError = error
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .googleAds, error: error))
            DDLogError("⛔️ Error loading Google ads campaigns: \(error)")
        }
        syncingData = false
    }

    func onViewAppear() {
        viewAppeared = true
    }

    func reloadCard() {
        Task {
            await reloadCard()
        }
    }
}

private extension GoogleAdsDashboardCardViewModel {

    func trackEntryPointDisplayedIfNeeded() {
        $canShowOnDashboard.removeDuplicates()
            .combineLatest($syncingData.removeDuplicates(), $viewAppeared)
            .filter { canShow, syncingData, viewAppeared in
                // only tracks the display if the view is done loaded and visible.
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
    func retrieveCampaignStats() async throws -> GoogleAdsCampaignStats {
        // Use midnight in the store timezone so negative offsets do not serialize the lower bound as 1969-12-31.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let epoch = Date(timeIntervalSince1970: 0)
        let fallbackDate = epoch.addingTimeInterval(TimeInterval(-timeZone.secondsFromGMT(for: epoch)))
        let earliestDateToInclude = calendar.date(from: DateComponents(year: 1970, month: 1, day: 1)) ?? fallbackDate

        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(GoogleAdsAction.retrieveCampaignStats(
                siteID: siteID,
                timeZone: timeZone,
                earliestDateToInclude: earliestDateToInclude,
                latestDateToInclude: Date.now) { result in
                    continuation.resume(with: result)
                }
            )
        }
    }
}
