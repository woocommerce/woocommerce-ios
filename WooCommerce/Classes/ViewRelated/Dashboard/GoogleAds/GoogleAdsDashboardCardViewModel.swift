import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `GoogleAdsDashboardCard`.
final class GoogleAdsDashboardCardViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let eligibilityChecker: GoogleAdsEligibilityChecker

    @Published private(set) var canShowOnDashboard = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var syncingData = false

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
        // TODO
    }
}
