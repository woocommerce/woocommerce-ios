@testable import PointOfSale

final class MockPOSCustomAmountTaxPreferences: POSCustomAmountTaxPreferenceStoring {
    var values: [Int64: Bool] = [:]
    private(set) var savedSiteIDs: [Int64] = []

    func isTaxable(for siteID: Int64) -> Bool {
        values[siteID] ?? false
    }

    func setTaxable(_ isTaxable: Bool, for siteID: Int64) {
        values[siteID] = isTaxable
        savedSiteIDs.append(siteID)
    }
}
