import Testing
@testable import Yosemite

@MainActor
struct AsyncPaginationTrackerTests {
    @Test func resync_and_ensureNextPageIsSynced_when_called_concurrently_from_the_main_actor_then_page_state_stays_consistent() async throws {
        // Given
        let tracker = AsyncPaginationTracker()
        let callCount = 2_000

        // When
        let calls = (0..<callCount).map { index in
            Task {
                if index.isMultiple(of: 2) {
                    try? await tracker.resync { @Sendable _ in false }
                } else {
                    _ = try? await tracker.ensureNextPageIsSynced { @Sendable _ in false }
                }
            }
        }
        for call in calls {
            await call.value
        }

        // Then
        #expect(tracker.hasNextPage == false)
    }
}
