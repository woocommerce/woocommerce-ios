import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite

final class BlazeStoreTests: XCTestCase {
    /// Mock network to inject responses
    ///
    private var network: MockNetwork!

    /// Spy remote to check request parameter use
    ///
    private var remote: MockBlazeRemote!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Storage
    ///
    private var storage: StorageType! {
        storageManager.viewStorage
    }

    /// Convenience: returns the StorageType associated with the main thread
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience: returns the number of stored campaigns
    ///
    private var storedCampaignCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeCampaign.self)
    }

    private var storedTargetDeviceCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeTargetDevice.self)
    }

    private var storedTargetLanguageCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeTargetLanguage.self)
    }

    /// SiteID
    ///
    private let sampleSiteID: Int64 = 120934

    /// Default page number
    ///
    private let defaultPageNumber = 1


    // MARK: - Set up and Tear down

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        storageManager = MockStorageManager()
        remote = MockBlazeRemote()
    }

    override func tearDown() {
        network = nil
        storageManager = nil
        remote = nil
        super.tearDown()
    }

    // MARK: - synchronizeCampaigns

    func test_synchronizeCampaigns_returns_false_for_hasNextPage_when_number_of_retrieved_results_is_zero() throws {
        // Given
        remote.whenLoadingCampaign(thenReturn: .success([]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaigns(siteID: self.sampleSiteID, pageNumber: self.defaultPageNumber, onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let hasNextPage = try result.get()
        XCTAssertFalse(hasNextPage)
    }

    func test_synchronizeCampaigns_returns_true_for_hasNextPage_when_number_of_retrieved_results_is_not_zero() throws {
        // Given
        remote.whenLoadingCampaign(thenReturn: .success([.fake()]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaigns(siteID: self.sampleSiteID, pageNumber: self.defaultPageNumber, onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let hasNextPage = try result.get()
        XCTAssertTrue(hasNextPage)
    }

    func test_synchronizeCampaigns_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingCampaign(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaigns(siteID: self.sampleSiteID, pageNumber: self.defaultPageNumber, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_synchronizeCampaigns_stores_campaigns_upon_success() throws {
        // Given
        remote.whenLoadingCampaign(thenReturn: .success([.fake().copy(campaignID: 123)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignCount, 0)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaigns(siteID: self.sampleSiteID, pageNumber: self.defaultPageNumber, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignCount, 1)
    }

    func test_synchronizeCampaign_deletes_campaigns_when_first_page_recieved_from_API() {
        // Given
        storeCampaign(.fake().copy(campaignID: 123), for: sampleSiteID)
        remote.whenLoadingCampaign(thenReturn: .success([.fake().copy(campaignID: 456)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignCount, 1)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaigns(siteID: self.sampleSiteID, pageNumber: self.defaultPageNumber, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignCount, 1)
    }

    func test_synchronizeCampaign_does_not_delete_campaigns_when_subsequent_pages_recieved_from_API() {
        // Given
        storeCampaign(.fake().copy(campaignID: 123), for: sampleSiteID)
        remote.whenLoadingCampaign(thenReturn: .success([.fake().copy(campaignID: 456)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignCount, 1)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaigns(siteID: self.sampleSiteID, pageNumber: 2, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignCount, 2)
    }

    // MARK: - Synchronize target devices

    func test_synchronizeTargetDevices_is_successful_when_fetching_successfully() throws {
        // Given
        remote.whenFetchingTargetDevices(thenReturn: .success([.fake().copy(id: "mobile")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetDevices(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let devices = try result.get()
        XCTAssertEqual(devices.count, 1)
    }

    func test_synchronizeTargetDevices_stores_devices_upon_success() throws {
        // Given
        remote.whenFetchingTargetDevices(thenReturn: .success([.fake().copy(id: "mobile")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedTargetDeviceCount, 0)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetDevices(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedTargetDeviceCount, 1)
    }

    func test_synchronizeTargetDevices_overwrites_existing_devices_with_the_given_locale() throws {
        // Given
        let locale = "vi"
        storeTargetDevice(.init(id: "test", name: "Test", locale: locale))
        storeTargetDevice(.init(id: "test-2", name: "Test 2", locale: "en"))
        remote.whenFetchingTargetDevices(thenReturn: .success([.init(id: "mobile", name: "Mobile", locale: locale)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedTargetDeviceCount, 2)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetDevices(siteID: self.sampleSiteID, locale: locale, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedTargetDeviceCount, 2)
        let devices = viewStorage.loadAllBlazeTargetDevices(locale: locale)
        XCTAssertEqual(devices.count, 1)
        let device = try XCTUnwrap(devices.first)
        XCTAssertEqual(device.id, "mobile")
        XCTAssertEqual(device.name, "Mobile")
        XCTAssertEqual(device.locale, locale)
    }

    func test_synchronizeTargetDevices_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingTargetDevices(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetDevices(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Synchronize target languages

    func test_synchronizeTargetLanguages_is_successful_when_fetching_successfully() throws {
        // Given
        remote.whenFetchingTargetLanguages(thenReturn: .success([.fake().copy(id: "en")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetLanguages(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let languages = try result.get()
        XCTAssertEqual(languages.count, 1)
    }

    func test_synchronizeTargetLanguages_stores_devices_upon_success() throws {
        // Given
        remote.whenFetchingTargetLanguages(thenReturn: .success([.fake().copy(id: "en")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedTargetLanguageCount, 0)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetLanguages(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedTargetLanguageCount, 1)
    }

    func test_synchronizeTargetLanguages_overwrites_existing_devices_with_the_given_locale() throws {
        // Given
        let locale = "en"
        storeTargetLanguage(.init(id: "test", name: "Test", locale: locale))
        storeTargetLanguage(.init(id: "test-2", name: "Test 2", locale: "vi"))
        remote.whenFetchingTargetLanguages(thenReturn: .success([.init(id: "en", name: "English", locale: locale)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedTargetLanguageCount, 2)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetLanguages(siteID: self.sampleSiteID, locale: locale, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedTargetLanguageCount, 2)
        let languages = viewStorage.loadAllBlazeTargetLanguages(locale: locale)
        XCTAssertEqual(languages.count, 1)
        let language = try XCTUnwrap(languages.first)
        XCTAssertEqual(language.id, "en")
        XCTAssertEqual(language.name, "English")
        XCTAssertEqual(language.locale, locale)
    }

    func test_synchronizeTargetLanguages_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingTargetLanguages(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetLanguages(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }
}

private extension BlazeStoreTests {
    @discardableResult
    func storeCampaign(_ campaign: Networking.BlazeCampaign, for siteID: Int64) -> Storage.BlazeCampaign {
        let storedCampaign = storage.insertNewObject(ofType: BlazeCampaign.self)
        storedCampaign.update(with: campaign)
        storedCampaign.siteID = siteID
        return storedCampaign
    }

    @discardableResult
    func storeTargetDevice(_ device: Networking.BlazeTargetDevice) -> Storage.BlazeTargetDevice {
        let storedDevice = storage.insertNewObject(ofType: BlazeTargetDevice.self)
        storedDevice.update(with: device)
        return storedDevice
    }

    @discardableResult
    func storeTargetLanguage(_ language: Networking.BlazeTargetLanguage) -> Storage.BlazeTargetLanguage {
        let storedLanguage = storage.insertNewObject(ofType: BlazeTargetLanguage.self)
        storedLanguage.update(with: language)
        return storedLanguage
    }
}
