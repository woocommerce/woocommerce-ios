@testable import PointOfSale

final class MockPOSCardPaymentHistory: POSCardPaymentHistoryProviding {
    var hasRecordedCardPayment = false
    private(set) var requestedSiteIDs: [Int64] = []

    func hasRecordedCardPayment(siteID: Int64) async -> Bool {
        requestedSiteIDs.append(siteID)
        return hasRecordedCardPayment
    }
}
