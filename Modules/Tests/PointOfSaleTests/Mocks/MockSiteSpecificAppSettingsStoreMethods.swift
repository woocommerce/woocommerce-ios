@testable import Yosemite
import Foundation
import Storage

/// Minimal mock for SiteSpecificAppSettingsStoreMethodsProtocol
/// Only implements the methods needed for POS local catalog tests
final class MockSiteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol {
    var currentSiteID: Int64 = 1

    // POS local catalog cellular data properties
    var getPOSLocalCatalogCellularDataAllowedCalled = false
    var setPOSLocalCatalogCellularDataAllowedCalled = false
    var mockPOSLocalCatalogCellularDataAllowed: Bool?

    // Implement only the methods we actually use
    func setPOSLocalCatalogCellularDataAllowed(siteID: Int64, allowed: Bool) {
        setPOSLocalCatalogCellularDataAllowedCalled = true
        mockPOSLocalCatalogCellularDataAllowed = allowed
    }

    func getPOSLocalCatalogCellularDataAllowed(siteID: Int64) -> Bool {
        getPOSLocalCatalogCellularDataAllowedCalled = true
        return mockPOSLocalCatalogCellularDataAllowed ?? false
    }

    // Protocol requirements - minimal implementations
    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        GeneralStoreSettings()
    }

    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)?) {
        onCompletion?(.success(()))
    }

    func resetStoreSettings() {}

    func setStoreID(siteID: Int64, id: String?) {}

    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {
        onCompletion(nil)
    }

    func getSearchTerms(for itemType: POSItemType, siteID: Int64) -> [String] {
        []
    }

    func setSearchTerms(_ terms: [String], for itemType: POSItemType, siteID: Int64) {}

    func getPOSLastOpenedDate(siteID: Int64) -> Date? {
        nil
    }

    func setPOSLastOpenedDate(siteID: Int64, date: Date) {}

    func getFirstPOSCatalogSyncDate(siteID: Int64) -> Date? {
        nil
    }

    func setFirstPOSCatalogSyncDate(siteID: Int64, date: Date) {}
}
