import XCTest
@testable import Networking
@testable import Yosemite

final class DomainStoreTests: XCTestCase {
    /// Mock Dispatcher.
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory.
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses.
    private var network: MockNetwork!

    private var remote: MockDomainRemote!
    private var store: DomainStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockDomainRemote()
        store = DomainStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    override func tearDown() {
        store = nil
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    // MARK: - `loadFreeDomainSuggestions`

    func test_loadFreeDomainSuggestions_returns_suggestions_on_success() throws {
        // Given
        remote.whenLoadingDomainSuggestions(thenReturn: .success([.init(name: "freedomaintesting", isFree: false)]))

        // When
        let result: Result<[FreeDomainSuggestion], Error> = waitFor { promise in
            let action = DomainAction.loadFreeDomainSuggestions(query: "domain") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [.init(name: "freedomaintesting", isFree: false)])
    }

    func test_loadFreeDomainSuggestions_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingDomainSuggestions(thenReturn: .failure(NetworkError.timeout))

        // When
        let result: Result<[FreeDomainSuggestion], Error> = waitFor { promise in
            let action = DomainAction.loadFreeDomainSuggestions(query: "domain") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    // MARK: - `loadDomains`

    func test_loadDomains_returns_domains_on_success() throws {
        // Given
        remote.whenLoadingDomains(thenReturn: .success([
            .init(name: "candy.land", isPrimary: true, renewalDate: .distantFuture),
            .init(name: "pods.pro", isPrimary: true)
        ]))

        // When
        let result: Result<[SiteDomain], Error> = waitFor { promise in
            self.store.onAction(DomainAction.loadDomains(siteID: 606) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [
            .init(name: "candy.land", isPrimary: true, renewalDate: .distantFuture),
            .init(name: "pods.pro", isPrimary: true)
        ])
    }

    func test_loadDomains_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingDomains(thenReturn: .failure(NetworkError.timeout))

        // When
        let result: Result<[SiteDomain], Error> = waitFor { promise in
            self.store.onAction(DomainAction.loadDomains(siteID: 606) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }
}
