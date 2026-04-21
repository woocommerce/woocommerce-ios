import XCTest
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class ReviewsDashboardCardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 1337
    private var stores: MockStoresManager!

    private let sampleReviews: [ProductReview] = [ProductReview.fake().copy(siteID: 1337, reviewID: 1),
                                 ProductReview.fake().copy(siteID: 1337, reviewID: 2),
                                 ProductReview.fake().copy(siteID: 1337, reviewID: 3)]

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        storageManager = nil
        super.tearDown()
    }

    @MainActor
    func test_reviews_are_loaded_from_storage_when_available() async {
        // Given
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager)
        insertReviews(sampleReviews)

        // When
        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleReviews))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.success(([], true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        await viewModel.reloadData()

        // Then
        let sortedExtractedReviews = viewModel.data
            .map { $0.review }
            .sorted { $0.reviewID < $1.reviewID }

        XCTAssertEqual(sortedExtractedReviews, self.sampleReviews)
    }

    @MainActor
    func test_syncingData_is_updated_correctly_when_syncing() async {
        // Given
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager)
        XCTAssertFalse(viewModel.syncingData)

        // When
        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                XCTAssertTrue(viewModel.syncingData)
                onCompletion(.success(self.sampleReviews))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.success(([], true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertFalse(viewModel.syncingData)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_syncing_reviews_fails() async {
        // Given
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)

        // When
        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.success(([], true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_syncing_products_fails() async {
        // Given
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)
        insertReviews(sampleReviews)

        // When
        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleReviews))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_syncing_notifications_fails() async {
        // Given
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)
        insertReviews(sampleReviews)

        // When
        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleReviews))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.success(([], true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                onCompletion(error)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }

    // MARK: - Woo-driven Push Notifications Tests

    @MainActor
    func test_supportsWPComNotifications_returns_true_when_site_not_registered_for_woo_pns() async {
        // Given
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [])

        // When
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager,
                                                      pushNotesManager: mockPushNotesManager)

        // Then
        XCTAssertTrue(viewModel.supportsWPComNotifications)
    }

    @MainActor
    func test_supportsWPComNotifications_returns_false_when_site_registered_for_woo_pns() async {
        // Given
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [sampleSiteID])

        // When
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager,
                                                      pushNotesManager: mockPushNotesManager)

        // Then
        XCTAssertFalse(viewModel.supportsWPComNotifications)
    }

    @MainActor
    func test_supportsWPComNotifications_returns_false_when_authenticated_without_wpcom() async {
        // Given
        let storesWithoutWPCom = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true, isWPCom: false))
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [])

        // When
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: storesWithoutWPCom,
                                                      storageManager: storageManager,
                                                      pushNotesManager: mockPushNotesManager)

        // Then
        XCTAssertFalse(viewModel.supportsWPComNotifications)
    }

    @MainActor
    func test_reloadData_skips_notification_sync_when_site_registered_for_woo_pns() async {
        // Given
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [sampleSiteID])
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager,
                                                      pushNotesManager: mockPushNotesManager)
        insertReviews(sampleReviews)

        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleReviews))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.success(([], true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        var notificationSyncCalled = false
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case .synchronizeNotifications:
                notificationSyncCalled = true
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        await viewModel.reloadData()

        // Then
        XCTAssertFalse(notificationSyncCalled)
    }

    @MainActor
    func test_reloadData_syncs_notifications_when_site_not_registered_for_woo_pns() async {
        // Given
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [])
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager,
                                                      pushNotesManager: mockPushNotesManager)
        insertReviews(sampleReviews)

        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleReviews))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                onCompletion(.success(([], true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        var notificationSyncCalled = false
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                notificationSyncCalled = true
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        await viewModel.reloadData()

        // Then
        XCTAssertTrue(notificationSyncCalled)
    }
}

extension ReviewsDashboardCardViewModelTests {
    func insertReviews(_ readOnlyReviews: [ProductReview]) {
        let expectation = expectation(description: "Insert reviews")
        storageManager.performAndSave({ storage in
            readOnlyReviews.forEach { review in
                let newReview = storage.insertNewObject(ofType: StorageProductReview.self)
                newReview.update(with: review)
            }
        }, completion: {
            expectation.fulfill()
        }, on: .main)
        wait(for: [expectation], timeout: 1.0)
    }
}
