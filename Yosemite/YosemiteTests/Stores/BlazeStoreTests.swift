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
        remote.whenLoadingCampaign(thenReturn: .failure(NetworkError.timeout))
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
        XCTAssertEqual(result.failure as? NetworkError, .timeout)
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

    func test_synchronizeCoupons_deletes_coupons_when_first_page_recieved_from_API() {
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

    func test_synchronizeCoupons_does_not_delete_coupons_when_subsequent_pages_recieved_from_API() {
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
}

private extension BlazeStoreTests {
    @discardableResult
    func storeCampaign(_ campaign: Networking.BlazeCampaign, for siteID: Int64) -> Storage.BlazeCampaign {
        let storedCampaign = storage.insertNewObject(ofType: BlazeCampaign.self)
        storedCampaign.update(with: campaign)
        storedCampaign.siteID = siteID
        return storedCampaign
    }
}
