import Testing
import Yosemite
import struct NetworkingCore.Note
@testable import WooCommerce

@MainActor
struct NotificationOpenCoordinatorTests {
    private let stores = MockStoresManager(sessionManager: SessionManager.testingInstance)
    private let notices = MockNoticePresenter()

    @Test func test_open_when_pos_blocks_navigation_then_drops_order_and_review() {
        let coordinator = makeCoordinator(beginNavigation: { nil })

        coordinator.open(notification(kind: .storeOrder))
        coordinator.open(notification(kind: .comment))

        #expect(stores.receivedActions.isEmpty)
        #expect(notices.queuedNotices.isEmpty)
    }

    @Test func test_open_when_review_lookup_fails_then_shows_notice() throws {
        let coordinator = makeCoordinator(beginNavigation: { { true } })

        coordinator.open(notification(kind: .comment))
        try failReviewLookup()

        #expect(notices.queuedNotices.count == 1)
    }

    @Test func test_open_when_session_ends_during_lookup_then_discards_result() throws {
        var isCurrent = true
        let coordinator = makeCoordinator(beginNavigation: { { isCurrent } })

        coordinator.open(notification(kind: .comment))
        isCurrent = false
        try failReviewLookup()

        #expect(notices.queuedNotices.isEmpty)
    }

    private func makeCoordinator(beginNavigation: @escaping () -> (() -> Bool)?) -> NotificationOpenCoordinator {
        stores.reset()
        return NotificationOpenCoordinator(stores: stores, noticePresenter: notices, beginNavigation: beginNavigation,
                                           showDetails: { _ in Issue.record("Unexpected order navigation") },
                                           showReview: { _ in Issue.record("Unexpected review navigation") })
    }

    private func failReviewLookup() throws {
        let action = try #require(stores.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = action else {
            Issue.record("Expected a review lookup")
            return
        }
        completion(.failure(CancellationError()))
    }

    private func notification(kind: Note.Kind) -> WooCommerce.PushNotification {
        WooCommerce.PushNotification(noteID: 1234, siteID: 1, kind: kind, title: "", subtitle: "", message: "", note: nil, meta: nil)
    }
}
