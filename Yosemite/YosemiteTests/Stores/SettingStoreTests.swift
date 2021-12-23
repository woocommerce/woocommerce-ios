import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// SettingStoreTests Unit Tests
///
class SettingStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }


    // MARK: - SettingAction.synchronizeGeneralSiteSettings

    /// Verifies that `SettingAction.synchronizeGeneralSiteSettings` effectively persists any retrieved SiteSettings.
    ///
    func testRetrieveGerneralSiteSettingsEffectivelyPersistsRetrievedSettings() {
        let expectation = self.expectation(description: "Persist general site settings")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)

        let action = SettingAction.synchronizeGeneralSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteSetting.self), 20)

            let readOnlySiteSetting = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleGeneralSiteSetting().settingID)
            XCTAssertEqual(readOnlySiteSetting?.toReadOnly(), self.sampleGeneralSiteSetting())

            let readOnlySiteSetting2 = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleGeneralSiteSetting2().settingID)
            XCTAssertEqual(readOnlySiteSetting2?.toReadOnly(), self.sampleGeneralSiteSetting2())

            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.synchronizeGeneralSiteSettings` effectively persists any updated SiteSettings.
    ///
    func testRetrieveGeneralSiteSettingsEffectivelyPersistsUpdatedSettings() {
        let expectation = self.expectation(description: "Persist updated general site settings")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general-alt")
        let action = SettingAction.synchronizeGeneralSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteSetting.self), 19)

            let readOnlySiteSetting = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleGeneralSiteSetting().settingID)
            XCTAssertEqual(readOnlySiteSetting?.toReadOnly(), self.sampleGeneralSiteSettingMutated())

            let readOnlySiteSetting2 = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleGeneralSiteSetting2().settingID)
            XCTAssertEqual(readOnlySiteSetting2?.toReadOnly(), self.sampleGeneralSiteSetting2Mutated())
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.synchronizeGeneralSiteSettings` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveGeneralSiteSettingsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve general site settings error response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "generic_error")
        let action = SettingAction.synchronizeGeneralSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.synchronizeGeneralSiteSettings` returns an error whenever there is no backend response.
    ///
    func testRetrieveGeneralSiteSettingsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve general site settings empty response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = SettingAction.synchronizeGeneralSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - SettingStore.upsertStoredGeneralSiteSettings

    /// Verifies that `upsertStoredGeneralSiteSettings` effectively inserts a new SiteSetting, with the specified payload.
    ///
    func testUpsertStoredGeneralSiteSettingsEffectivelyPersistsNewSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteSettings = [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()].sorted()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)

        let storageSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.general.rawValue)
        XCTAssertNotNil(storageSiteSettings)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        XCTAssertEqual(storageSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteSiteSettings)
    }

    /// Verifies that `upsertStoredGeneralSiteSettings` does not produce duplicate entries.
    ///
    func testUpsertStoredGeneralSiteSettingsEffectivelyUpdatesPreexistantSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSettingMutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSettingMutated(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSettingMutated(), sampleGeneralSiteSetting2Mutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        let expectedSiteSetting = sampleGeneralSiteSettingMutated()
        let storageSiteSetting = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleGeneralSiteSettingMutated().settingID)
        XCTAssertEqual(storageSiteSetting?.toReadOnly(), expectedSiteSetting)

        let expectedSiteSetting2 = sampleGeneralSiteSetting2Mutated()
        let storageSiteSetting2 = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleGeneralSiteSetting2Mutated().settingID)
        XCTAssertEqual(storageSiteSetting2?.toReadOnly(), expectedSiteSetting2)
    }

    /// Verifies that `upsertStoredGeneralSiteSettings` removes previously stored SiteSettings correctly.
    ///
    func testUpsertStoredGeneralSiteSettingsEffectivelyRemovesInvalidSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting2Mutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)

        let expectedSiteSetting = sampleGeneralSiteSetting2Mutated()
        let storageSiteSetting = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleGeneralSiteSetting2Mutated().settingID)
        XCTAssertEqual(storageSiteSetting?.toReadOnly(), expectedSiteSetting)
    }

    /// Verifies that `upsertStoredGeneralSiteSettings` removes previously stored SiteSettings correctly if an empty read-only array is passed in.
    ///
    func testUpsertStoredGeneralSiteSettingsEffectivelyRemovesSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
    }


    // MARK: - SettingAction.synchronizeProductSiteSettings

    /// Verifies that `SettingAction.synchronizeProductSiteSettings` effectively persists any retrieved SiteSettings.
    ///
    func testRetrieveProductSiteSettingsEffectivelyPersistsRetrievedSettings() {
        let expectation = self.expectation(description: "Persist product site settings")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "settings/products", filename: "settings-product")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)

        let action = SettingAction.synchronizeProductSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteSetting.self), 23)

            let readOnlySiteSetting = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleProductSiteSetting().settingID)
            XCTAssertEqual(readOnlySiteSetting?.toReadOnly(), self.sampleProductSiteSetting())

            let readOnlySiteSetting2 = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleProductSiteSetting2().settingID)
            XCTAssertEqual(readOnlySiteSetting2?.toReadOnly(), self.sampleProductSiteSetting2())

            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.synchronizeProductSiteSettings` effectively persists any updated SiteSettings.
    ///
    func testRetrieveProductSiteSettingsEffectivelyPersistsUpdatedSettings() {
        let expectation = self.expectation(description: "Persist updated product site settings")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting(), sampleProductSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        network.simulateResponse(requestUrlSuffix: "settings/products", filename: "settings-product-alt")
        let action = SettingAction.synchronizeProductSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteSetting.self), 22)

            let readOnlySiteSetting = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleProductSiteSetting().settingID)
            XCTAssertEqual(readOnlySiteSetting?.toReadOnly(), self.sampleProductSiteSettingMutated())

            let readOnlySiteSetting2 = self.viewStorage.loadSiteSetting(siteID: self.sampleSiteID, settingID: self.sampleProductSiteSetting2().settingID)
            XCTAssertEqual(readOnlySiteSetting2?.toReadOnly(), self.sampleProductSiteSetting2Mutated())
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.synchronizeProductSiteSettings` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveProductSiteSettingsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve product site settings error response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "settings/products", filename: "generic_error")
        let action = SettingAction.synchronizeProductSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `SettingAction.synchronizeProductSiteSettings` returns an error whenever there is no backend response.
    ///
    func testRetrieveProductSiteSettingsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve product site settings empty response")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = SettingAction.synchronizeProductSiteSettings(siteID: sampleSiteID) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        settingStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - SettingStore.upsertStoredProductSiteSettings

    /// Verifies that `upsertStoredProductSiteSettings` effectively inserts a new SiteSetting, with the specified payload.
    ///
    func testUpsertStoredProductSiteSettingsEffectivelyPersistsNewSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteSettings = [sampleProductSiteSetting(), sampleProductSiteSetting2()].sorted()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting(), sampleProductSiteSetting2()],
                                                     in: viewStorage)

        let storageSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.product.rawValue)
        XCTAssertNotNil(storageSiteSettings)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        XCTAssertEqual(storageSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteSiteSettings)
    }

    /// Verifies that `upsertStoredProductSiteSettings` does not produce duplicate entries.
    ///
    func testUpsertStoredProductSiteSettingsEffectivelyUpdatesPreexistantSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSettingMutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSettingMutated(), sampleProductSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSettingMutated(), sampleProductSiteSetting2Mutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        let expectedSiteSetting = sampleProductSiteSettingMutated()
        let storageSiteSetting = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleProductSiteSettingMutated().settingID)
        XCTAssertEqual(storageSiteSetting?.toReadOnly(), expectedSiteSetting)

        let expectedSiteSetting2 = sampleProductSiteSetting2Mutated()
        let storageSiteSetting2 = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleProductSiteSetting2Mutated().settingID)
        XCTAssertEqual(storageSiteSetting2?.toReadOnly(), expectedSiteSetting2)
    }

    /// Verifies that `upsertStoredProductSiteSettings` removes previously stored SiteSettings correctly.
    ///
    func testUpsertStoredProductSiteSettingsEffectivelyRemovesInvalidSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting(), sampleProductSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting2Mutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)

        let expectedSiteSetting = sampleProductSiteSetting2Mutated()
        let storageSiteSetting = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sampleProductSiteSetting2Mutated().settingID)
        XCTAssertEqual(storageSiteSetting?.toReadOnly(), expectedSiteSetting)
    }

    /// Verifies that `upsertStoredProductSiteSettings` removes previously stored SiteSettings correctly if an empty read-only array is passed in.
    ///
    func testUpsertStoredProductSiteSettingsEffectivelyRemovesSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting(), sampleProductSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)
        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
    }


    // MARK: - Misc SettingStore Upsert Tests

    /// Verifies that `upsertStored*SiteSettings` effectively persists SiteSettings for multiple setting groups
    ///
    func testUpsertMultipleSiteSettingsGroupsEffectivelyPersistsSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteGeneralSiteSettings = [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()].sorted()
        let remoteProductSiteSettings = [sampleProductSiteSetting(), sampleProductSiteSetting2()].sorted()
        let remoteAllSiteSettings = [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2(), sampleProductSiteSetting(), sampleProductSiteSetting2()].sorted()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting(), sampleProductSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 4)

        let storageSiteSettings = viewStorage.loadAllSiteSettings(siteID: sampleSiteID)
        XCTAssertNotNil(storageSiteSettings)
        XCTAssertEqual(storageSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteAllSiteSettings)

        let storageGeneralSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.general.rawValue)
        XCTAssertNotNil(storageGeneralSiteSettings)
        XCTAssertEqual(storageGeneralSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteGeneralSiteSettings)

        let storageProductSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.product.rawValue)
        XCTAssertNotNil(storageProductSiteSettings)
        XCTAssertEqual(storageProductSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteProductSiteSettings)
    }

    /// Verifies that `upsertStored*SiteSettings` effectively updates + prunes SiteSettings for multiple setting groups
    ///
    func testUpsertMultipleSiteSettingsGroupsEffectivelyUpdatesSiteSettings() {
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteGeneralSiteSettings = [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()].sorted()
        let remoteProductSiteSettings = [sampleProductSiteSetting(), sampleProductSiteSetting2()].sorted()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)
        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting(), sampleGeneralSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting(), sampleProductSiteSetting2()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 4)

        let storageGeneralSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.general.rawValue)
        XCTAssertNotNil(storageGeneralSiteSettings)
        XCTAssertEqual(storageGeneralSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteGeneralSiteSettings)

        let storageProductSiteSettings = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.product.rawValue)
        XCTAssertNotNil(storageProductSiteSettings)
        XCTAssertEqual(storageProductSiteSettings?.map({ $0.toReadOnly() }).sorted(), remoteProductSiteSettings)

        settingStore.upsertStoredGeneralSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleGeneralSiteSetting2Mutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 3)

        settingStore.upsertStoredProductSiteSettings(siteID: sampleSiteID,
                                                     readOnlySiteSettings: [sampleProductSiteSetting2Mutated()],
                                                     in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        let storageGeneralSiteSettings2 = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.general.rawValue)
        XCTAssertNotNil(storageGeneralSiteSettings2)
        XCTAssertEqual(storageGeneralSiteSettings2?.map({ $0.toReadOnly() }).sorted(), [sampleGeneralSiteSetting2Mutated()])

        let storageProductSiteSettings2 = viewStorage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: SiteSettingGroup.product.rawValue)
        XCTAssertNotNil(storageProductSiteSettings2)
        XCTAssertEqual(storageProductSiteSettings2?.map({ $0.toReadOnly() }).sorted(), [sampleProductSiteSetting2Mutated()])
    }

    func test_advanced_site_gets_stored_correctly() throws {
        // Given
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "settings/advanced", filename: "settings-advanced")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 0)

        // When
        let action = SettingAction.synchronizeAdvancedSiteSettings(siteID: sampleSiteID) { _ in }
        settingStore.onAction(action)

        // Then
        waitUntil {
            self.viewStorage.countObjects(ofType: Storage.SiteSetting.self) == 2
        }
    }

    func test_advanced_site_gets_updated_correctly() throws {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: sampleAdvancedSiteSettingMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 1)

        network.simulateResponse(requestUrlSuffix: "settings/advanced", filename: "settings-advanced")
        let settingStore = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let completed: Bool = waitFor { promise in
            let action = SettingAction.synchronizeAdvancedSiteSettings(siteID: self.sampleSiteID) { _ in
                promise(true)
            }
            settingStore.onAction(action)
        }


        // Then
        XCTAssertTrue(completed)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSetting.self), 2)

        let sample = sampleAdvancedSiteSetting()
        let updated = viewStorage.loadSiteSetting(siteID: sampleSiteID, settingID: sample.settingID)?.toReadOnly()
        XCTAssertEqual(sample, updated)
    }


    // MARK: - SettingAction.retrieveSiteAPI

    /// Verifies that `SettingAction.retrieveSiteAPI` returns the expected API information.
    ///
    func test_retrieveSiteAPI_returns_expected_status() throws {
        // Given
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "", filename: "site-api")

        // When
        let result: Result<SiteAPI, Error> = waitFor { promise in
            let action = SettingAction.retrieveSiteAPI(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteAPI = try result.get()
        XCTAssertEqual(siteAPI, sampleSiteAPIWithWoo())
    }

    /// Verifies that `SettingAction.retrieveSiteAPI` returns the expected API information.
    ///
    func test_retrieveSiteAPI_returns_expected_status_for_non_woo_site() throws {
        // Given
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "", filename: "site-api-no-woo")

        // When
        let result: Result<SiteAPI, Error> = waitFor { promise in
            let action = SettingAction.retrieveSiteAPI(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteAPI = try result.get()
        XCTAssertEqual(siteAPI, sampleSiteAPINoWoo())
    }

    /// Verifies that `SettingAction.retrieveSiteAPI` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveSiteAPI_returns_error_upon_reponse_error() {
        // Given
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "", filename: "generic_error")

        // When
        let result: Result<SiteAPI, Error> = waitFor { promise in
            let action = SettingAction.retrieveSiteAPI(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `SettingAction.retrieveSiteAPI` returns an error whenever there is no backend response.
    ///
    func test_retrieveSiteAPI_returns_error_upon_empty_response() {
        // Given
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<SiteAPI, Error> = waitFor { promise in
            let action = SettingAction.retrieveSiteAPI(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_getPaymentsPagePath_returns_page_when_setting_is_stored() throws {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: sampleAdvancedSiteSetting())
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<String, SettingStore.SettingError> = waitFor { promise in
            let action = SettingAction.getPaymentsPagePath(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let paymentPath = try result.get()
        XCTAssertEqual(paymentPath, sampleAdvancedSiteSetting().value)
    }

    func test_getPaymentsPagePath_returns_error_when_setting_is_not_stored() throws {
        // Given
        let store = SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<String, SettingStore.SettingError> = waitFor { promise in
            let action = SettingAction.getPaymentsPagePath(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .paymentsPageNotFound)
    }
}


// MARK: - Private Methods
//
private extension SettingStoreTests {

    // MARK: - General SiteSetting Samples

    func sampleGeneralSiteSetting() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_currency",
                           label: "Currency",
                           settingDescription: "This controls what currency prices are listed at in the catalog"
                            + " and which currency gateways will take payments in.",
                           value: "USD",
                           settingGroupKey: SiteSettingGroup.general.rawValue)
    }

    func sampleGeneralSiteSettingMutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_currency",
                           label: "Currency!",
                           settingDescription: "This controls what currency prices are listed!",
                           value: "GBP",
                           settingGroupKey: SiteSettingGroup.general.rawValue)
    }

    func sampleGeneralSiteSetting2() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_price_thousand_sep",
                           label: "Thousand separator",
                           settingDescription: "This sets the thousand separator of displayed prices.",
                           value: ",",
                           settingGroupKey: SiteSettingGroup.general.rawValue)
    }

    func sampleGeneralSiteSetting2Mutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_price_thousand_sep",
                           label: "Thousand separator!!",
                           settingDescription: "This sets the thousand separator!!",
                           value: "~",
                           settingGroupKey: SiteSettingGroup.general.rawValue)
    }

    // MARK: - Product SiteSetting Samples

    func sampleProductSiteSetting() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_dimension_unit",
                           label: "Dimensions unit",
                           settingDescription: "This controls what unit you will define lengths in.",
                           value: "m",
                           settingGroupKey: SiteSettingGroup.product.rawValue)
    }

    func sampleProductSiteSettingMutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_dimension_unit",
                           label: "Dimension Fruit",
                           settingDescription: "This controls what fruit you will define lengths in.",
                           value: "Kumquat",
                           settingGroupKey: SiteSettingGroup.product.rawValue)
    }

    func sampleProductSiteSetting2() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_weight_unit",
                           label: "Weight unit",
                           settingDescription: "This controls what unit you will define weights in.",
                           value: "kg",
                           settingGroupKey: SiteSettingGroup.product.rawValue)
    }

    func sampleProductSiteSetting2Mutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_weight_unit",
                           label: "Animal unit",
                           settingDescription: "This controls what animal you will define weights in.",
                           value: "elephants",
                           settingGroupKey: SiteSettingGroup.product.rawValue)
    }

    // MARK: - Advanced SiteSetting Samples

    func sampleAdvancedSiteSetting() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_checkout_pay_endpoint",
                           label: "Pay",
                           settingDescription: "Endpoint for the pay page",
                           value: "order-pay",
                           settingGroupKey: SiteSettingGroup.advanced.rawValue)
    }

    func sampleAdvancedSiteSettingMutated() -> Networking.SiteSetting {
        return SiteSetting(siteID: sampleSiteID,
                           settingID: "woocommerce_checkout_pay_endpoint",
                           label: "Pay",
                           settingDescription: "Endpoint for the pay page",
                           value: "order-pay-2",
                           settingGroupKey: SiteSettingGroup.advanced.rawValue)
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
