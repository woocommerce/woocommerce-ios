import Synchronization
@testable import Yosemite
import Foundation
import Storage

final class MockSiteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol, Sendable {
    private struct State {
        var getStoreSettingsCalled: Bool = false
        var setStoreSettingsCalled: Bool = false
        var resetStoreSettingsCalled: Bool = false
        var setStoreIDCalled: Bool = false
        var getStoreIDCalled: Bool = false
        var spySetStoreID: String? = nil
        var spySetStoreIDSiteID: Int64? = nil
        var spyGetStoreIDSiteID: Int64? = nil
        var storeSettings = GeneralStoreSettings()
        var mockStoreID: String?
        var mockError: Error?
        var currentSiteID: Int64 = 1
        var getSearchTermsCalled: Bool = false
        var setSearchTermsCalled: Bool = false
        var spyGetSearchTermsItemType: POSItemType?
        var spyGetSearchTermsSiteID: Int64?
        var spySetSearchTermsItemType: POSItemType?
        var spySetSearchTermsSiteID: Int64?
        var mockSearchTerms: [POSItemType: [String]] = [:]
        var getPOSLastOpenedDateCalled: Bool = false
        var setPOSLastOpenedDateCalled: Bool = false
        var getFirstPOSCatalogSyncDateCalled: Bool = false
        var setFirstPOSCatalogSyncDateCalled: Bool = false
        var mockPOSLastOpenedDate: Date?
        var mockFirstPOSCatalogSyncDate: Date?
        var getPOSLocalCatalogCellularDataAllowedCalled: Bool = false
        var setPOSLocalCatalogCellularDataAllowedCalled: Bool = false
        var mockPOSLocalCatalogCellularDataAllowed: Bool?
        var setPOSCatalogFileBlockedByHostAtCalled: Bool = false
        var isPOSCatalogFileBlockedByHostCalled: Bool = false
        var mockPOSCatalogFileBlockedByHostAt: Date?
    }

    private let state = Mutex(State())

    var getStoreSettingsCalled: Bool {
        get { state.withLock { $0.getStoreSettingsCalled } }
        set { state.withLock { $0.getStoreSettingsCalled = newValue } }
    }

    var setStoreSettingsCalled: Bool {
        get { state.withLock { $0.setStoreSettingsCalled } }
        set { state.withLock { $0.setStoreSettingsCalled = newValue } }
    }

    var resetStoreSettingsCalled: Bool {
        get { state.withLock { $0.resetStoreSettingsCalled } }
        set { state.withLock { $0.resetStoreSettingsCalled = newValue } }
    }

    var setStoreIDCalled: Bool {
        get { state.withLock { $0.setStoreIDCalled } }
        set { state.withLock { $0.setStoreIDCalled = newValue } }
    }

    var getStoreIDCalled: Bool {
        get { state.withLock { $0.getStoreIDCalled } }
        set { state.withLock { $0.getStoreIDCalled = newValue } }
    }

    var spySetStoreID: String? {
        get { state.withLock { $0.spySetStoreID } }
        set { state.withLock { $0.spySetStoreID = newValue } }
    }

    var spySetStoreIDSiteID: Int64? {
        get { state.withLock { $0.spySetStoreIDSiteID } }
        set { state.withLock { $0.spySetStoreIDSiteID = newValue } }
    }

    var spyGetStoreIDSiteID: Int64? {
        get { state.withLock { $0.spyGetStoreIDSiteID } }
        set { state.withLock { $0.spyGetStoreIDSiteID = newValue } }
    }

    var storeSettings: GeneralStoreSettings {
        get { state.withLock { $0.storeSettings } }
        set { state.withLock { $0.storeSettings = newValue } }
    }

    var mockStoreID: String? {
        get { state.withLock { $0.mockStoreID } }
        set { state.withLock { $0.mockStoreID = newValue } }
    }

    var mockError: Error? {
        get { state.withLock { $0.mockError } }
        set { state.withLock { $0.mockError = newValue } }
    }

    var currentSiteID: Int64 {
        get { state.withLock { $0.currentSiteID } }
        set { state.withLock { $0.currentSiteID = newValue } }
    }

    // Search terms properties
    var getSearchTermsCalled: Bool {
        get { state.withLock { $0.getSearchTermsCalled } }
        set { state.withLock { $0.getSearchTermsCalled = newValue } }
    }

    var setSearchTermsCalled: Bool {
        get { state.withLock { $0.setSearchTermsCalled } }
        set { state.withLock { $0.setSearchTermsCalled = newValue } }
    }

    var spyGetSearchTermsItemType: POSItemType? {
        get { state.withLock { $0.spyGetSearchTermsItemType } }
        set { state.withLock { $0.spyGetSearchTermsItemType = newValue } }
    }

    var spyGetSearchTermsSiteID: Int64? {
        get { state.withLock { $0.spyGetSearchTermsSiteID } }
        set { state.withLock { $0.spyGetSearchTermsSiteID = newValue } }
    }

    var spySetSearchTermsItemType: POSItemType? {
        get { state.withLock { $0.spySetSearchTermsItemType } }
        set { state.withLock { $0.spySetSearchTermsItemType = newValue } }
    }

    var spySetSearchTermsSiteID: Int64? {
        get { state.withLock { $0.spySetSearchTermsSiteID } }
        set { state.withLock { $0.spySetSearchTermsSiteID = newValue } }
    }

    var mockSearchTerms: [POSItemType: [String]] {
        get { state.withLock { $0.mockSearchTerms } }
        set { state.withLock { $0.mockSearchTerms = newValue } }
    }

    // POS sync eligibility tracking properties
    var getPOSLastOpenedDateCalled: Bool {
        get { state.withLock { $0.getPOSLastOpenedDateCalled } }
        set { state.withLock { $0.getPOSLastOpenedDateCalled = newValue } }
    }

    var setPOSLastOpenedDateCalled: Bool {
        get { state.withLock { $0.setPOSLastOpenedDateCalled } }
        set { state.withLock { $0.setPOSLastOpenedDateCalled = newValue } }
    }

    var getFirstPOSCatalogSyncDateCalled: Bool {
        get { state.withLock { $0.getFirstPOSCatalogSyncDateCalled } }
        set { state.withLock { $0.getFirstPOSCatalogSyncDateCalled = newValue } }
    }

    var setFirstPOSCatalogSyncDateCalled: Bool {
        get { state.withLock { $0.setFirstPOSCatalogSyncDateCalled } }
        set { state.withLock { $0.setFirstPOSCatalogSyncDateCalled = newValue } }
    }

    var mockPOSLastOpenedDate: Date? {
        get { state.withLock { $0.mockPOSLastOpenedDate } }
        set { state.withLock { $0.mockPOSLastOpenedDate = newValue } }
    }

    var mockFirstPOSCatalogSyncDate: Date? {
        get { state.withLock { $0.mockFirstPOSCatalogSyncDate } }
        set { state.withLock { $0.mockFirstPOSCatalogSyncDate = newValue } }
    }

    var getPOSLocalCatalogCellularDataAllowedCalled: Bool {
        get { state.withLock { $0.getPOSLocalCatalogCellularDataAllowedCalled } }
        set { state.withLock { $0.getPOSLocalCatalogCellularDataAllowedCalled = newValue } }
    }

    var setPOSLocalCatalogCellularDataAllowedCalled: Bool {
        get { state.withLock { $0.setPOSLocalCatalogCellularDataAllowedCalled } }
        set { state.withLock { $0.setPOSLocalCatalogCellularDataAllowedCalled = newValue } }
    }

    var mockPOSLocalCatalogCellularDataAllowed: Bool? {
        get { state.withLock { $0.mockPOSLocalCatalogCellularDataAllowed } }
        set { state.withLock { $0.mockPOSLocalCatalogCellularDataAllowed = newValue } }
    }

    var setPOSCatalogFileBlockedByHostAtCalled: Bool {
        get { state.withLock { $0.setPOSCatalogFileBlockedByHostAtCalled } }
        set { state.withLock { $0.setPOSCatalogFileBlockedByHostAtCalled = newValue } }
    }

    var isPOSCatalogFileBlockedByHostCalled: Bool {
        get { state.withLock { $0.isPOSCatalogFileBlockedByHostCalled } }
        set { state.withLock { $0.isPOSCatalogFileBlockedByHostCalled = newValue } }
    }

    var mockPOSCatalogFileBlockedByHostAt: Date? {
        get { state.withLock { $0.mockPOSCatalogFileBlockedByHostAt } }
        set { state.withLock { $0.mockPOSCatalogFileBlockedByHostAt = newValue } }
    }

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
        state.withLock { $0.mockSearchTerms[itemType] = terms }
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

    func setPOSCatalogFileBlockedByHostAt(siteID: Int64, date: Date?) {
        setPOSCatalogFileBlockedByHostAtCalled = true
        mockPOSCatalogFileBlockedByHostAt = date
    }

    func getPOSCatalogFileBlockedByHostAt(siteID: Int64) -> Date? {
        mockPOSCatalogFileBlockedByHostAt
    }

    func isPOSCatalogFileBlockedByHost(siteID: Int64) -> Bool {
        isPOSCatalogFileBlockedByHostCalled = true
        return mockPOSCatalogFileBlockedByHostAt != nil
    }
}
