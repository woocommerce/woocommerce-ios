
import Foundation
import XCTest

import Yosemite

@testable import WooCommerce

/// Test cases for `ReviewsCoordinator`.
///
final class ReviewsCoordinatorTests: XCTestCase {
    private var pushNotificationsManager: MockPushNotificationsManager!
    private var storesManager: MockupStoresManager!
    private var sessionManager: SessionManager!
    private var noticePresenter: MockNoticePresenter!
    private var switchStoreUseCase: MockSwitchStoreUseCase!

    private var reviewsCoordinator: ReviewsCoordinator!

    override func setUp() {
        super.setUp()

        pushNotificationsManager = MockPushNotificationsManager()
        sessionManager = SessionManager.testingInstance

        storesManager = MockupStoresManager(sessionManager: sessionManager)
        // Reset `receivedActions`
        storesManager.reset()

        noticePresenter = MockNoticePresenter()
        switchStoreUseCase = MockSwitchStoreUseCase()

        reviewsCoordinator = ReviewsCoordinator(pushNotificationsManager: pushNotificationsManager,
                                                storesManager: storesManager,
                                                noticePresenter: noticePresenter,
                                                switchStoreUseCase: switchStoreUseCase)
    }

    override func tearDown() {
        reviewsCoordinator = nil
        switchStoreUseCase = nil
        noticePresenter = nil
        storesManager = nil
        sessionManager = nil
        pushNotificationsManager = nil

        super.tearDown()
    }

    func testWhenReceivingANonReviewNotificationThenItWillNotDoAnything() throws {
        // Given
        let pushNotification = PushNotification(noteID: 1_234, kind: .storeOrder, message: "")

        let navigationController = reviewsCoordinator.navigationController
        reviewsCoordinator.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Wait for runloop to make sure NavigationController pushes happen
        RunLoop.current.run(until: Date())

        // Then
        assertEmpty(storesManager.receivedActions)

        // Only the Reviews list is shown
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        let currentViewController = try XCTUnwrap(navigationController.viewControllers.first)
        assertThat(currentViewController, isAnInstanceOf: ReviewsViewController.self)
    }

    func testWhenReceivingANotificationWhileInForegroundThenItWillNotDoAnything() throws {
        // Given
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, message: "")

        let navigationController = reviewsCoordinator.navigationController
        reviewsCoordinator.start()

        // When
        pushNotificationsManager.sendForegroundNotification(pushNotification)

        // Wait for runloop to make sure NavigationController pushes happen
        RunLoop.current.run(until: Date())

        // Then
        assertEmpty(storesManager.receivedActions)

        // Only the Reviews list is shown
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        let currentViewController = try XCTUnwrap(navigationController.viewControllers.first)
        assertThat(currentViewController, isAnInstanceOf: ReviewsViewController.self)
    }

    func testWhenReceivingAReviewNotificationWhileInactiveThenItWillPresentTheReviewDetails() throws {
        // Given
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, message: "")

        let navigationController = reviewsCoordinator.navigationController
        reviewsCoordinator.start()

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(makeParcel()))

        // Wait for runloop to make sure NavigationController pushes happen
        RunLoop.current.run(until: Date())

        // Then
        // A ReviewDetailsViewController should be pushed
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        let topViewController = try XCTUnwrap(navigationController.topViewController)
        assertThat(topViewController, isAnInstanceOf: ReviewDetailsViewController.self)
    }

    func testWhenFailingToRetrieveProductReviewDetailsThenItWillPresentANotice() throws {
        // Given
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, message: "")

        let navigationController = reviewsCoordinator.navigationController
        reviewsCoordinator.start()

        assertEmpty(noticePresenter.queuedNotices)

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.failure(NSError(domain: "domain", code: 0)))

        // Wait for runloop to make sure NavigationController pushes happen
        RunLoop.current.run(until: Date())

        // Then
        // A Notice should have been presented
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)

        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, ReviewsCoordinator.Localization.failedToRetrieveNotificationDetails)

        // Only the Reviews list should still be visible
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        let topViewController = try XCTUnwrap(navigationController.topViewController)
        assertThat(topViewController, isAnInstanceOf: ReviewsViewController.self)
    }

    func testWhenReceivingAReviewNotificationFromADifferentSiteThenItWillSwitchTheCurrentSite() throws {
        // Given
        sessionManager.setStoreId(1_000)

        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, message: "")
        let differentSiteID: Int64 = 2_000_111

        let navigationController = reviewsCoordinator.navigationController
        reviewsCoordinator.start()

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel from a different site
        let receivedProductReviewAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedProductReviewAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(makeParcel(metaSiteID: differentSiteID)))

        waitUntil {
            navigationController.viewControllers.count >= 2
        }

        // Then
        // A ReviewDetailsViewController should be pushed
        assertThat(navigationController.topViewController, isAnInstanceOf: ReviewDetailsViewController.self)
        // We should have switched to the other site
        XCTAssertEqual(switchStoreUseCase.destinationStoreIDs, [differentSiteID])
    }
}

// MARK: - Utils

private extension ReviewsCoordinatorTests {
    /// Create a dummy Parcel.
    func makeParcel(metaSiteID: Int64 = 0) -> ProductReviewFromNoteParcel {
        let metaAsData: Data = {
            var ids = [String: Int64]()
            ids[MetaContainer.Keys.site.rawValue] = metaSiteID

            var metaAsJSON = [String: [String: Int64]]()
            metaAsJSON[MetaContainer.Containers.ids.rawValue] = ids
            do {
                return try JSONEncoder().encode(metaAsJSON)
            } catch {
                XCTFail("Expected to convert MetaContainer JSON to Data. \(error)")
                return Data()
            }
        }()

        let note = Note(noteID: 1,
                        hash: 0,
                        read: false,
                        icon: nil,
                        noticon: nil,
                        timestamp: "",
                        type: "",
                        subtype: nil,
                        url: nil,
                        title: nil,
                        subject: Data(),
                        header: Data(),
                        body: Data(),
                        meta: metaAsData)
        let product = MockProduct().product()
        let review = MockReviews().anonyousReview()

        return ProductReviewFromNoteParcel(note: note, review: review, product: product)
    }
}
