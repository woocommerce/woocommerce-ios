import Testing
@testable import Yosemite

@MainActor
struct AsyncPaginationTrackerTests {
    @Test func resync_and_ensureNextPageIsSynced_when_called_concurrently_from_the_main_actor_then_page_state_stays_consistent() async throws {
        // Given
        let tracker = AsyncPaginationTracker()
        let callCount = 2_000

        // When
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<callCount {
                group.addTask { @MainActor in
                    if index.isMultiple(of: 2) {
                        try? await tracker.resync { _ in false }
                    } else {
                        _ = try? await tracker.ensureNextPageIsSynced { _ in false }
                    }
                }
            }
        }

        // Then
        #expect(tracker.hasNextPage == false)
    }
}
