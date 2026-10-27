import XCTest
@testable import WooCommerce

/// Verifies that concurrent access to TracksProvider does not crash.
/// This covers the fix for WOOMOB-2668 where concurrent `track()` and
/// `refreshUserData()` calls raced on TracksService's NSMutableDictionary.
final class TracksProviderThreadSafetyTests: XCTestCase {

    @MainActor
    func test_init_when_called_off_main_does_not_wait_for_main_thread() {
        // Given
        let initializationStarted = DispatchGroup()
        initializationStarted.enter()
        let initializationFinished = DispatchGroup()
        initializationFinished.enter()

        // When
        DispatchQueue.global().async {
            initializationStarted.leave()
            _ = TracksProvider(consent: MockAnalyticsConsent())
            initializationFinished.leave()
        }

        // Then
        // A synchronous main-thread wait reproduces the static-initialization deadlock if init hops to main synchronously.
        XCTAssertEqual(initializationStarted.wait(timeout: .now() + 5), .success)
        XCTAssertEqual(initializationFinished.wait(timeout: .now() + 5), .success)
    }

    func test_init_when_device_type_is_provided_uses_it() {
        // Given
        let deviceType = "test_device"

        // When
        let provider = TracksProvider(consent: MockAnalyticsConsent(), deviceTypeForAnalytics: deviceType)

        // Then
        XCTAssertEqual(provider.deviceTypeForAnalytics, deviceType)
    }

    func test_concurrent_track_and_refreshUserData_does_not_crash() {
        // Given
        let provider = TracksProvider(consent: MockAnalyticsConsent())
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
                provider.refreshUserData {
                    allDone.fulfill()
                }
            }
        }

        // Then — reaching here without EXC_BAD_ACCESS or NSGenericException means the fix works
        wait(for: [allDone], timeout: 30.0)
    }

    func test_refreshUserData_calls_completion_after_queued_refresh() {
        // Given
        let provider = TracksProvider(consent: MockAnalyticsConsent())
        let refreshCompleted = expectation(description: "Refresh completed")

        // When
        provider.refreshUserData {
            refreshCompleted.fulfill()
        }

        // Then
        wait(for: [refreshCompleted], timeout: 5.0)
    }
}
