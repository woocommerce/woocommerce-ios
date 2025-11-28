@testable import Yosemite
import Foundation
import Storage

final class MockSiteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol {
    var getStoreSettingsCalled = false
    var setStoreSettingsCalled = false
    var resetStoreSettingsCalled = false
    var setStoreIDCalled = false
    var getStoreIDCalled = false
    var spySetStoreID: String? = nil
    var spySetStoreIDSiteID: Int64? = nil

    var spyGetStoreIDSiteID: Int64? = nil

    var storeSettings = GeneralStoreSettings()
    var mockStoreID: String?
    var mockError: Error?

    var currentSiteID: Int64 = 1

    // Search terms properties
    var getSearchTermsCalled = false
    var setSearchTermsCalled = false
    var spyGetSearchTermsItemType: POSItemType?
    var spyGetSearchTermsSiteID: Int64?
    var spySetSearchTermsItemType: POSItemType?
    var spySetSearchTermsSiteID: Int64?
    var mockSearchTerms: [POSItemType: [String]] = [:]

    // POS sync eligibility tracking properties
    var getPOSLastOpenedDateCalled = false
    var setPOSLastOpenedDateCalled = false
    var getFirstPOSCatalogSyncDateCalled = false
    var setFirstPOSCatalogSyncDateCalled = false
    var mockPOSLastOpenedDate: Date?
    var mockFirstPOSCatalogSyncDate: Date?
    var getPOSLocalCatalogCellularDataAllowedCalled = false
    var setPOSLocalCatalogCellularDataAllowedCalled = false
    var mockPOSLocalCatalogCellularDataAllowed: Bool?


    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        getStoreSettingsCalled = true
        return storeSettings
    }

    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)?) {
        setStoreSettingsCalled = true

        guard siteID == currentSiteID else {
            onCompletion?(.success(()))
            return
        }

        storeSettings = settings
        if let error = mockError {
            onCompletion?(.failure(error))
        } else {
            onCompletion?(.success(()))
        }
    }

    func resetStoreSettings() {
        resetStoreSettingsCalled = true
        storeSettings = GeneralStoreSettings()
    }

    func setStoreID(siteID: Int64, id: String?) {
        setStoreIDCalled = true
        spySetStoreID = id
        spySetStoreIDSiteID = siteID
        guard siteID == currentSiteID else {
            return
        }
        mockStoreID = id
    }

    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {
        getStoreIDCalled = true
        spyGetStoreIDSiteID = siteID
        onCompletion(mockStoreID)
    }

    // Search terms methods
    func getSearchTerms(for itemType: POSItemType, siteID: Int64) -> [String] {
        getSearchTermsCalled = true
        spyGetSearchTermsItemType = itemType
        spyGetSearchTermsSiteID = siteID
        return mockSearchTerms[itemType] ?? []
    }

    func setSearchTerms(_ terms: [String], for itemType: POSItemType, siteID: Int64) {
        setSearchTermsCalled = true
        spySetSearchTermsItemType = itemType
        spySetSearchTermsSiteID = siteID
        mockSearchTerms[itemType] = terms
    }

    // POS sync eligibility tracking methods
    func getPOSLastOpenedDate(siteID: Int64) -> Date? {
        getPOSLastOpenedDateCalled = true
        return mockPOSLastOpenedDate
    }

    func setPOSLastOpenedDate(siteID: Int64, date: Date) {
        setPOSLastOpenedDateCalled = true
        mockPOSLastOpenedDate = date
    }

    func getFirstPOSCatalogSyncDate(siteID: Int64) -> Date? {
        getFirstPOSCatalogSyncDateCalled = true
        return mockFirstPOSCatalogSyncDate
    }

    func setFirstPOSCatalogSyncDate(siteID: Int64, date: Date) {
        setFirstPOSCatalogSyncDateCalled = true
        mockFirstPOSCatalogSyncDate = date
    }

    func setPOSLocalCatalogCellularDataAllowed(siteID: Int64, allowed: Bool) {
        setPOSLocalCatalogCellularDataAllowedCalled = true
        mockPOSLocalCatalogCellularDataAllowed = allowed
    }

    func getPOSLocalCatalogCellularDataAllowed(siteID: Int64) -> Bool {
        getPOSLocalCatalogCellularDataAllowedCalled = true
        return mockPOSLocalCatalogCellularDataAllowed ?? false
    }
}
