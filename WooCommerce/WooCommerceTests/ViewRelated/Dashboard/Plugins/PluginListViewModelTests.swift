import XCTest
@testable import Storage
@testable import WooCommerce
@testable import Yosemite

class PluginListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 134

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// View storage for tests
    ///
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_syncPlugins_dispatches_synchronizeSitePlugins_action_with_correct_siteID() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        var triggeredSiteID: Int64?
        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .synchronizeSystemInformation(let siteID, _):
                triggeredSiteID = siteID
            default:
                break
            }
        }
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        viewModel.syncPlugins { _ in }

        // Then
        XCTAssertEqual(triggeredSiteID, sampleSiteID)
    }

    func test_syncPlugins_returns_success_when_synchronizeSitePlugins_action_completes_successfully() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .synchronizeSystemInformation(_, let completion):
                completion(.success(.fake()))
            default:
                break
            }
        }
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            viewModel.syncPlugins { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_syncPlugins_returns_error_when_synchronizeSitePlugins_action_fails() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .synchronizeSystemInformation(_, let completion):
                completion(.failure(MockPluginError.mockError))
            default:
                break
            }
        }
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            viewModel.syncPlugins { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}

// MARK: - Mock types
//
private extension PluginListViewModelTests {
    enum MockPluginError: Error {
        case mockError
    }
}
