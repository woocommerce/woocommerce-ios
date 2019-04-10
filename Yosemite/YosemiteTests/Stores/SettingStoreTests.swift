import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// SettingStoreTests Unit Tests
///
class SettingStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }


    // MARK: - SettingAction.retrieveSiteSettings


    /// Verifies that `SettingAction.retrieveSiteSettings` effectively persists any retrieved SiteSettings.
    ///
    func testRetrieveSiteSettingsEffectivelyPersistsRetrievedSettings() {
        let expectation = self.expectation(description: "Persist site settings")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)

        let action = SettingAction.retrieveSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteSetting.self), 20)

            let readOnlySiteSetting = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleSiteSetting().settingID)
            XCTAssertEqual(readOnlySiteSetting?.toReadOnly(), self.sampleSiteSetting())

            let readOnlySiteSetting2 = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleSiteSetting2().settingID)
            XCTAssertEqual(readOnlySiteSetting2?.toReadOnly(), self.sampleSiteSetting2())

            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.retrieveSiteSettings` effectively persists any updated SiteSettings.
    ///
    func testRetrieveSiteSettingsEffectivelyPersistsUpdatedSettings() {
        let expectation = self.expectation(description: "Persist updated site settings")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSetting(), sampleSiteSetting2()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general-alt")
        let action = SettingAction.retrieveSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteSetting.self), 20)

            let readOnlySiteSetting = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleSiteSetting().settingID)
            XCTAssertEqual(readOnlySiteSetting?.toReadOnly(), self.sampleSiteSettingMutated())

            let readOnlySiteSetting2 = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleSiteSetting2().settingID)
            XCTAssertEqual(readOnlySiteSetting2?.toReadOnly(), self.sampleSiteSetting2Mutated())
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.retrieveSiteSettings` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSiteSettingsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve site settings error response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "generic_error")
        let action = SettingAction.retrieveSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.retrieveSiteSettings` returns an error whenever there is no backend response.
    ///
    func testRetrieveSiteSettingsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site settings empty response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = SettingAction.retrieveSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredSiteSettings` effectively inserts a new SiteSetting, with the specified payload.
    ///
    func testUpsertStoredSiteSettingsEffectivelyPersistsNewSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteSettings = [sampleSiteSetting(), sampleSiteSetting2()].sorted()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSetting(), sampleSiteSetting2()])

        let storageSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID)
        XCTAssertNotNil(storageSiteSettings)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        XCTAssertEqual(storageSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteSiteSettings)
    }

    /// Verifies that `upsertStoredSiteSettings` does not produce duplicate entries.
    ///
    func testUpsertStoredSiteSettingsEffectivelyUpdatesPreexistantSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSetting()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSettingMutated()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSettingMutated(), sampleSiteSetting2()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSettingMutated(), sampleSiteSetting2Mutated()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        let expectedSiteSetting = sampleSiteSettingMutated()
        let storageSiteSetting = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleSiteSettingMutated().settingID)
        XCTAssertEqual(storageSiteSetting?.toReadOnly(), expectedSiteSetting)

        let expectedSiteSetting2 = sampleSiteSetting2Mutated()
        let storageSiteSetting2 = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleSiteSetting2Mutated().settingID)
        XCTAssertEqual(storageSiteSetting2?.toReadOnly(), expectedSiteSetting2)
    }

    /// Verifies that `upsertStoredSiteSettings` removes previously stored SiteSettings correctly.
    ///
    func testUpsertStoredSiteSettingsEffectivelyRemovesInvalidSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSetting(), sampleSiteSetting2()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSetting2Mutated()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)

        let expectedSiteSetting = sampleSiteSetting2Mutated()
        let storageSiteSetting = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleSiteSetting2Mutated().settingID)
        XCTAssertEqual(storageSiteSetting?.toReadOnly(), expectedSiteSetting)
    }

    /// Verifies that `upsertStoredSiteSettings` removes previously stored SiteSettings correctly if an empty read-only array is passed in.
    ///
    func testUpsertStoredSiteSettingsEffectivelyRemovesSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [sampleSiteSetting(), sampleSiteSetting2()])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredSiteSettings(siteID: sampleSiteID, readOnlySiteSettings: [])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
    }


    // MARK: - SettingAction.retrieveSiteAPI


    /// Verifies that `SettingAction.retrieveSiteAPI` returns the expected API information.
    ///
    func testRetrieveSiteAPIReturnsExpectedStatus() {
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Retrieve Site API info successfully")

        network.simulateResponse(requestUrlSuffix: "", filename: "site-api")
        let action = SettingAction.retrieveSiteAPI(siteID: sampleSiteID) { (siteAPI, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteAPI)
            XCTAssertEqual(siteAPI, self.sampleSiteAPIWithWoo())
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.retrieveSiteAPI` returns the expected API information.
    ///
    func testRetrieveSiteAPIReturnsExpectedStatusForNonWooSite() {
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Retrieve Site API info successfully for non-Woo site")

        network.simulateResponse(requestUrlSuffix: "", filename: "site-api-no-woo")
        let action = SettingAction.retrieveSiteAPI(siteID: sampleSiteID) { (siteAPI, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteAPI)
            XCTAssertEqual(siteAPI, self.sampleSiteAPINoWoo())
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.retrieveSiteAPI` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSiteAPIReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve Site API info error response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "", filename: "generic_error")
        let action = SettingAction.retrieveSiteAPI(siteID: sampleSiteID) { (siteAPI, error) in
            XCTAssertNil(siteAPI)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.retrieveSiteAPI` returns an error whenever there is no backend response.
    ///
    func testRetrieveSiteAPIReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve Site API info empty response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = SettingAction.retrieveSiteAPI(siteID: sampleSiteID) { (siteAPI, error) in
            XCTAssertNil(siteAPI)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Methods
//
private extension SettingStoreTests {

    // MARK: - SiteSetting Samples

    func sampleSiteSetting() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_currency",
                           label: "Currency",
                           description: "This controls what currency prices are listed at in the catalog and which currency gateways will take payments in.",
                           value: "USD")
    }

    func sampleSiteSettingMutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_currency",
                           label: "Currency!",
                           description: "This controls what currency prices are listed!",
                           value: "GBP")
    }

    func sampleSiteSetting2() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_price_thousand_sep",
                           label: "Thousand separator",
                           description: "This sets the thousand separator of displayed prices.",
                           value: ",")
    }

    func sampleSiteSetting2Mutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_price_thousand_sep",
                           label: "Thousand separator!!",
                           description: "This sets the thousand separator!!",
                           value: "~")
    }

    // MARK: - SiteAPI Samples

    func sampleSiteAPIWithWoo() -> Networking.SiteAPI {
        return SiteAPI(siteID: sampleSiteID,
                       namespaces: ["oembed/1.0", "akismet/v1", "jetpack/v4", "wpcom/v2", "wc/v1", "wc/v2", "wc/v3", "wc-pb/v3", "wp/v2"])
    }

    func sampleSiteAPINoWoo() -> Networking.SiteAPI {
        return SiteAPI(siteID: sampleSiteID,
                       namespaces: ["oembed/1.0", "akismet/v1", "jetpack/v4", "wpcom/v2", "wc-pb/v3", "wp/v2"])
    }
}
