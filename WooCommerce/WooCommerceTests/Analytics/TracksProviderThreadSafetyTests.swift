import XCTest
@testable import WooCommerce

/// Verifies that concurrent access to TracksProvider does not crash.
/// This covers the fix for WOOMOB-2668 where concurrent `track()` and
/// `refreshUserData()` calls raced on TracksService's NSMutableDictionary.
final class TracksProviderThreadSafetyTests: XCTestCase {

    func test_concurrent_track_and_refreshUserData_does_not_crash() {
        // Given
        let provider = TracksProvider()
        let iterations = 50
        let allDone = expectation(description: "All concurrent operations completed")
        allDone.expectedFulfillmentCount = iterations * 2

        // When
        for _ in 0..<iterations {
            DispatchQueue.global().async {
                provider.track("thread_safety_test_event")
                allDone.fulfill()
            }
            DispatchQueue.global().async {
                provider.refreshUserData()
                allDone.fulfill()
            }
        }

        // Then — reaching here without EXC_BAD_ACCESS or NSGenericException means the fix works
        wait(for: [allDone], timeout: 30.0)
    }
}
