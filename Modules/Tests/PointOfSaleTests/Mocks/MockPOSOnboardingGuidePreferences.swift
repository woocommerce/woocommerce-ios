@testable import PointOfSale

final class MockPOSOnboardingGuidePreferences: POSOnboardingGuidePreferenceStoring {
    var completedSiteIDs: Set<Int64> = []
    private(set) var markedSiteIDs: [Int64] = []

    func hasCompletedGuide(for siteID: Int64) -> Bool {
        completedSiteIDs.contains(siteID)
    }

    func markGuideCompleted(for siteID: Int64) {
        completedSiteIDs.insert(siteID)
        markedSiteIDs.append(siteID)
    }
}
