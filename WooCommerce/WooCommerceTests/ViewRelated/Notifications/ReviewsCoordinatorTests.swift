
import Foundation
import XCTest

import Yosemite

@testable import WooCommerce

/// Test cases for `ReviewsCoordinator`.
///
final class ReviewsCoordinatorTests: XCTestCase {
    private var pushNotificationsManager: MockPushNotificationsManager!
    private var storesManager: MockupStoresManager!
    private var noticePresenter: MockNoticePresenter!

    private var reviewsCoordinator: ReviewsCoordinator!

    override func setUp() {
        super.setUp()

        pushNotificationsManager = MockPushNotificationsManager()
        storesManager = MockupStoresManager(sessionManager: SessionManager.testingInstance)
        noticePresenter = MockNoticePresenter()

        reviewsCoordinator = ReviewsCoordinator(pushNotificationsManager: pushNotificationsManager,
                                                storesManager: storesManager,
                                                noticePresenter: noticePresenter)
    }

    override func tearDown() {
        reviewsCoordinator = nil
        noticePresenter = nil
        storesManager = nil
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

        // Simulate that the network call return a parcel
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

        // Simulate that the network call return a parcel
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
}

// MARK: - Utils

private extension ReviewsCoordinatorTests {
    /// Create a dummy Parcel.
    func makeParcel() -> ProductReviewFromNoteParcel {
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
                        meta: Data())
        let product = MockProduct().product()
        let review = MockReviews().anonyousReview()

        return ProductReviewFromNoteParcel(note: note, review: review, product: product)
    }
}
