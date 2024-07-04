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

    @Published private(set) var canShowOnDashboard = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var syncingData = false
    @Published private(set) var lastCampaign: GoogleAdsCampaign?

    init(siteID: Int64,
         eligibilityChecker: GoogleAdsEligibilityChecker = DefaultGoogleAdsEligibilityChecker(),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.eligibilityChecker = eligibilityChecker
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
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .googleAds))
        do {
            let campaigns = try await fetchAdsCampaigns()
            lastCampaign = campaigns.last
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .googleAds))
        } catch {
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .googleAds, error: error))
            DDLogError("⛔️ Error loading Google ads campaigns: \(error)")
        }
    }
}

private extension GoogleAdsDashboardCardViewModel {
    @MainActor
    func fetchAdsCampaigns() async throws -> [GoogleAdsCampaign] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(GoogleAdsAction.fetchAdsCampaigns(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
    }
}
