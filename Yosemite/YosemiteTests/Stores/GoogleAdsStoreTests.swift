import XCTest
@testable import Networking
@testable import Yosemite

final class GoogleAdsStoreTests: XCTestCase {

    /// Mock network to inject responses
    ///
    private var network: MockNetwork!

    /// Spy remote to check request parameter use
    ///
    private var remote: MockGoogleListingsAndAdsRemote!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    private let sampleSiteID: Int64 = 120934

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = MockGoogleListingsAndAdsRemote()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        network = nil
        remote = nil
        storageManager = nil
        super.tearDown()
    }

    // MARK: - Check connection

    func test_checkConnection_returns_connection_on_success() throws {
        // Given
        let store = GoogleAdsStore(dispatcher: Dispatcher(),
                                   storageManager: storageManager,
                                   network: network,
                                   remote: remote)
        let connection = GoogleAdsConnection.fake().copy(id: 234, rawStatus: "incomplete")
        remote.whenCheckingConnection(thenReturn: .success(connection))

        // When
        let result = waitFor { promise in
            store.onAction(GoogleAdsAction.checkConnection(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        let receivedConnection = try result.get()
        assertEqual(connection, receivedConnection)
    }

    func test_checkConnection_returns_error_on_failure() throws {
        // Given
        let store = GoogleAdsStore(dispatcher: Dispatcher(),
                                   storageManager: storageManager,
                                   network: network,
                                   remote: remote)
        remote.whenCheckingConnection(thenReturn: .failure(NetworkError.timeout()))

        // When
        let result = waitFor { promise in
            store.onAction(GoogleAdsAction.checkConnection(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetch campaigns

    func test_checkCampaigns_returns_campaign_list_on_success() throws {
        // Given
        let store = GoogleAdsStore(dispatcher: Dispatcher(),
                                   storageManager: storageManager,
                                   network: network,
                                   remote: remote)
        let campaign = GoogleAdsCampaign.fake().copy(id: 1355234, amount: 30, country: "VN")
        remote.whenFetchingAdsCampaigns(thenReturn: .success([campaign]))

        // When
        let result = waitFor { promise in
            store.onAction(GoogleAdsAction.fetchAdsCampaigns(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        let receivedCampaigns = try result.get()
        assertEqual([campaign], receivedCampaigns)
    }

    func test_fetchCampaigns_returns_error_on_failure() throws {
        // Given
        let store = GoogleAdsStore(dispatcher: Dispatcher(),
                                   storageManager: storageManager,
                                   network: network,
                                   remote: remote)
        remote.whenFetchingAdsCampaigns(thenReturn: .failure(NetworkError.timeout()))

        // When
        let result = waitFor { promise in
            store.onAction(GoogleAdsAction.fetchAdsCampaigns(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }
}
