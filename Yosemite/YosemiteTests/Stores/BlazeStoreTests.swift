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

    /// Convenience: returns the number of stored brief campaigns
    ///
    private var storedCampaignListCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeCampaignListItem.self)
    }

    private var storedTargetDeviceCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeTargetDevice.self)
    }

    private var storedTargetLanguageCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeTargetLanguage.self)
    }

    private var storedTargetTopicCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeTargetTopic.self)
    }

    private var storedCampaignObjectiveCount: Int {
        return viewStorage.countObjects(ofType: StorageBlazeCampaignObjective.self)
    }

    /// SiteID
    ///
    private let sampleSiteID: Int64 = 120934

    /// Default page number
    ///
    private let defaultPageNumber = 1

    /// Default pagination limit
    ///
    private let defaultPaginationSkip = 0

    /// Default pagination limit
    ///
    private let defaultPaginationLimit = 1

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

    // MARK: - Create campaign

    func test_createCampaign_does_not_throw_errors_upon_success() throws {
        // Given
        remote.whenCreatingCampaign(thenReturn: .success(()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.createCampaign(campaign: .fake(),
                                                      siteID: self.sampleSiteID,
                                                      onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        try result.get()
    }

    func test_createCampaign_returns_error_on_failure() throws {
        // Given
        remote.whenCreatingCampaign(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.createCampaign(campaign: .fake(),
                                                      siteID: self.sampleSiteID,
                                                      onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }


    // MARK: - synchronizeCampaignsList

    func test_synchronizeCampaignsList_returns_false_for_hasNextPage_when_number_of_retrieved_results_is_zero() throws {
        // Given
        remote.whenLoadingCampaignList(thenReturn: .success([]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignsList(siteID: self.sampleSiteID,
                                                                 skip: self.defaultPaginationSkip,
                                                                 limit: self.defaultPaginationLimit,
                                                                 onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let hasNextPage = try result.get()
        XCTAssertFalse(hasNextPage)
    }

    func test_synchronizeCampaignsList_returns_true_for_hasNextPage_when_number_of_retrieved_results_is_not_zero() throws {
        // Given
        remote.whenLoadingCampaignList(thenReturn: .success([.fake()]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignsList(siteID: self.sampleSiteID,
                                                                 skip: self.defaultPaginationSkip,
                                                                 limit: self.defaultPaginationLimit,
                                                                 onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let hasNextPage = try result.get()
        XCTAssertTrue(hasNextPage)
    }

    func test_synchronizeCampaignsList_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingCampaignList(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignsList(siteID: self.sampleSiteID,
                                                                 skip: self.defaultPaginationSkip,
                                                                 limit: self.defaultPaginationLimit,
                                                                 onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_synchronizeCampaignsList_stores_campaigns_upon_success() throws {
        // Given
        remote.whenLoadingCampaignList(thenReturn: .success([.fake().copy(campaignID: "123")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignListCount, 0)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignsList(siteID: self.sampleSiteID,
                                                                 skip: self.defaultPaginationSkip,
                                                                 limit: self.defaultPaginationLimit,
                                                                 onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignListCount, 1)
    }

    func test_synchronizeCampaignsList_deletes_campaigns_when_items_recieved_from_API_with_zero_as_pagination_skip_value() {
        // Given
        storeCampaignListItem(.fake().copy(siteID: sampleSiteID, campaignID: "123"))
        remote.whenLoadingCampaignList(thenReturn: .success([.fake().copy(campaignID: "456")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignListCount, 1)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignsList(siteID: self.sampleSiteID,
                                                                 skip: self.defaultPaginationSkip,
                                                                 limit: self.defaultPaginationLimit,
                                                                 onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignListCount, 1)
    }

    func test_synchronizeCampaignsList_does_not_delete_campaigns_when_receiving_subsequent_items_using_non_zero_pagination_skip_value() {
        // Given
        storeCampaignListItem(.fake().copy(siteID: sampleSiteID, campaignID: "123"))
        remote.whenLoadingCampaignList(thenReturn: .success([.fake().copy(campaignID: "456")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignListCount, 1)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignsList(siteID: self.sampleSiteID,
                                                                 skip: 2,
                                                                 limit: self.defaultPaginationLimit,
                                                                 onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignListCount, 2)
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

    func test_synchronizeTargetLanguages_stores_languages_upon_success() throws {
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

    func test_synchronizeTargetLanguages_overwrites_existing_languages_with_the_given_locale() throws {
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

    // MARK: - Synchronize target topics

    func test_synchronizeTargetTopics_is_successful_when_fetching_successfully() throws {
        // Given
        remote.whenFetchingTargetTopics(thenReturn: .success([.fake().copy(id: "IAB1")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetTopics(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let topics = try result.get()
        XCTAssertEqual(topics.count, 1)
    }

    func test_synchronizeTargetTopics_stores_topics_upon_success() throws {
        // Given
        remote.whenFetchingTargetTopics(thenReturn: .success([.fake().copy(id: "IAB1")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedTargetTopicCount, 0)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetTopics(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedTargetTopicCount, 1)
    }

    func test_synchronizeTargetTopics_overwrites_existing_topics_with_the_given_locale() throws {
        // Given
        let locale = "en"
        storeTargetTopic(.init(id: "test", name: "Test", locale: locale))
        storeTargetTopic(.init(id: "test-2", name: "Test 2", locale: "vi"))
        remote.whenFetchingTargetTopics(thenReturn: .success([.init(id: "IAB1", name: "Arts", locale: locale)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedTargetTopicCount, 2)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetTopics(siteID: self.sampleSiteID, locale: locale, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedTargetTopicCount, 2)
        let topics = viewStorage.loadAllBlazeTargetTopics(locale: locale)
        XCTAssertEqual(topics.count, 1)
        let topic = try XCTUnwrap(topics.first)
        XCTAssertEqual(topic.id, "IAB1")
        XCTAssertEqual(topic.name, "Arts")
        XCTAssertEqual(topic.locale, locale)
    }

    func test_synchronizeTargetTopics_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingTargetTopics(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeTargetTopics(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetching target locations

    func test_fetchTargetLocations_is_successful_when_fetching_successfully() throws {
        // Given
        remote.whenFetchingTargetLocations(thenReturn: .success([.fake().copy(id: 123)]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchTargetLocations(siteID: self.sampleSiteID, query: "test", locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let locations = try result.get()
        XCTAssertEqual(locations.count, 1)
    }

    func test_fetchTargetLocations_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingTargetLocations(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchTargetLocations(siteID: self.sampleSiteID, query: "test", locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetching forecasted impressions

    func test_fetchForecastedImpressions_is_successful_when_fetching_successfully() throws {
        // Given
        remote.whenFetchingForecastedImpressions(thenReturn: .success(.fake().copy(totalImpressionsMax: 12345)))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchForecastedImpressions(siteID: self.sampleSiteID,
                                                                  input: BlazeForecastedImpressionsInput.fake(),
                                                                  onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let impressions = try result.get()
        XCTAssertEqual(impressions.totalImpressionsMax, 12345)
    }

    func test_fetchForecastedImpressions_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingForecastedImpressions(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchForecastedImpressions(siteID: self.sampleSiteID,
                                                                  input: BlazeForecastedImpressionsInput.fake(),
                                                                  onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetching AI suggestions

    func test_fetchAISuggestions_returns_suggestions_when_fetching_successfully() throws {
        // Given
        let suggestions = [BlazeAISuggestion(siteName: "Name 1", textSnippet: "Description 1"),
                           BlazeAISuggestion(siteName: "Name 2", textSnippet: "Description 2")]
        remote.whenFetchingAISuggestionsResult(thenReturn: .success(suggestions))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchAISuggestions(siteID: self.sampleSiteID,
                                                          productID: 123,
                                                          onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let value = try result.get()
        XCTAssertEqual(value, suggestions)
    }

    func test_fetchAISuggestions_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingAISuggestionsResult(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchAISuggestions(siteID: self.sampleSiteID,
                                                          productID: 123,
                                                          onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetching payment info

    func test_fetchPaymentInfo_is_successful_when_fetching_successfully() throws {
        // Given
        let paymentInfo = BlazePaymentInfo.fake().copy(
            paymentMethods: [])
        remote.whenFetchingPaymentInfo(thenReturn: .success(paymentInfo))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchPaymentInfo(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let info = try result.get()
        XCTAssertEqual(info, paymentInfo)
    }

    func test_fetchPaymentInfo_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingPaymentInfo(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.fetchPaymentInfo(siteID: self.sampleSiteID,
                                                        onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Synchronize campaign objectives

    func test_synchronizeCampaignObjectives_is_successful_when_fetching_successfully() throws {
        // Given
        remote.whenFetchingCampaignObjectives(thenReturn: .success([.fake().copy(id: "sale")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignObjectives(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        //Then
        let objectives = try result.get()
        XCTAssertEqual(objectives.count, 1)
    }

    func test_synchronizeCampaignObjectives_stores_devices_upon_success() throws {
        // Given
        remote.whenFetchingCampaignObjectives(thenReturn: .success([.fake().copy(id: "sale")]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignObjectiveCount, 0)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignObjectives(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignObjectiveCount, 1)
    }

    func test_synchronizeCampaignObjectives_overwrites_existing_objective_with_the_given_locale() throws {
        // Given
        let locale = "vi"
        storeCampaignObjectives(.init(id: "test", title: "Test", description: "", suitableForDescription: "", locale: locale))
        storeCampaignObjectives(.init(id: "test-2", title: "Test 2", description: "", suitableForDescription: "", locale: "en"))

        let expectedObjective = BlazeCampaignObjective(id: "sale", title: "Sale", description: "", suitableForDescription: "", locale: locale)
        remote.whenFetchingCampaignObjectives(thenReturn: .success([expectedObjective]))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)
        XCTAssertEqual(storedCampaignObjectiveCount, 2)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignObjectives(siteID: self.sampleSiteID, locale: locale, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCampaignObjectiveCount, 2)
        let objectives = viewStorage.loadAllBlazeCampaignObjectives(locale: locale)
        XCTAssertEqual(objectives.count, 1)
        let objective = try XCTUnwrap(objectives.first)
        XCTAssertEqual(objective.id, "sale")
        XCTAssertEqual(objective.title, "Sale")
        XCTAssertEqual(objective.locale, locale)
    }

    func test_synchronizeCampaignObjectives_returns_error_on_failure() throws {
        // Given
        remote.whenFetchingCampaignObjectives(thenReturn: .failure(NetworkError.timeout()))
        let store = BlazeStore(dispatcher: Dispatcher(),
                               storageManager: storageManager,
                               network: network,
                               remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(BlazeAction.synchronizeCampaignObjectives(siteID: self.sampleSiteID, locale: "en", onCompletion: { result in
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
    func storeCampaignListItem(_ campaign: Networking.BlazeCampaignListItem) -> Storage.BlazeCampaignListItem {
        let storedCampaign = storage.insertNewObject(ofType: BlazeCampaignListItem.self)
        storedCampaign.update(with: campaign)
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

    @discardableResult
    func storeTargetTopic(_ topic: Networking.BlazeTargetTopic) -> Storage.BlazeTargetTopic {
        let storedTopic = storage.insertNewObject(ofType: BlazeTargetTopic.self)
        storedTopic.update(with: topic)
        return storedTopic
    }

    @discardableResult
    func storeCampaignObjectives(_ objective: Networking.BlazeCampaignObjective) -> Storage.BlazeCampaignObjective {
        let storedItem = storage.insertNewObject(ofType: BlazeCampaignObjective.self)
        storedItem.update(with: objective)
        return storedItem
    }
}
