import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct ListRefreshUpdatesTests {
    @Test
    func test_perform_when_not_refreshing_then_updates_immediately() {
        // Given
        let updates = ListRefreshUpdates()
        var displayedValue = 0

        // When
        updates.perform { displayedValue = 1 }

        // Then
        #expect(displayedValue == 1)
    }

    @Test
    func test_refresh_when_model_changes_then_renders_latest_value_once_after_ending() async {
        // Given
        let updates = ListRefreshUpdates()
        let refreshControl = UIRefreshControl()
        var modelValue = 0
        var displayedValue = 0
        var renderCount = 0

        // When
        await withCheckedContinuation { continuation in
            updates.beginRefreshing {
                displayedValue = modelValue
                renderCount += 1
                continuation.resume()
            }
            for value in 1...3 {
                modelValue = value
                updates.perform { displayedValue = value }
            }
            #expect(displayedValue == 0)
            updates.endRefreshing(refreshControl)
        }

        // Then
        #expect(displayedValue == 3)
        #expect(renderCount == 1)
        updates.perform { displayedValue = 4 }
        #expect(displayedValue == 4)
    }

    @Test
    func test_cancel_when_request_never_completes_then_renders_once_and_resumes_updates() {
        // Given
        let updates = ListRefreshUpdates()
        var renderCount = 0
        var updateCount = 0
        updates.beginRefreshing { renderCount += 1 }
        updates.perform { updateCount += 1 }

        // When
        updates.cancel()
        updates.cancel()
        updates.perform { updateCount += 1 }

        // Then
        #expect(renderCount == 1)
        #expect(updateCount == 1)
    }

    @Test
    func test_cancel_when_dismissal_is_pending_then_does_not_render_twice() async {
        // Given
        let updates = ListRefreshUpdates()
        let refreshControl = RefreshControlStartingAnotherRefresh()
        var renderCount = 0
        updates.beginRefreshing { renderCount += 1 }

        // When
        await withCheckedContinuation { continuation in
            CATransaction.begin()
            CATransaction.setCompletionBlock { continuation.resume() }
            refreshControl.onEndRefreshing = { updates.cancel() }
            updates.endRefreshing(refreshControl)
            CATransaction.commit()
        }

        // Then
        #expect(renderCount == 1)
    }

    @Test
    func test_older_dismissal_when_another_refresh_starts_then_keeps_new_updates_deferred() async {
        // Given
        let updates = ListRefreshUpdates()
        let refreshControl = RefreshControlStartingAnotherRefresh()
        var oldRenderCount = 0
        var newRenderCount = 0
        var updateCount = 0
        updates.beginRefreshing { oldRenderCount += 1 }

        // When: another refresh begins before the first dismissal transaction completes.
        await withCheckedContinuation { continuation in
            refreshControl.onEndRefreshing = {
                updates.beginRefreshing {
                    newRenderCount += 1
                    continuation.resume()
                }
            }
            updates.endRefreshing(refreshControl)
            updates.perform { updateCount += 1 }
            refreshControl.onEndRefreshing = nil
            updates.endRefreshing(refreshControl)
        }

        // Then
        #expect(oldRenderCount == 0)
        #expect(newRenderCount == 1)
        #expect(updateCount == 0)
    }
}


@MainActor
private final class RefreshControlStartingAnotherRefresh: UIRefreshControl {
    var onEndRefreshing: (() -> Void)?

    override func endRefreshing() {
        super.endRefreshing()
        onEndRefreshing?()
    }
}
