import Foundation
@testable import WooCommerce

final class MockPOSTabVisibilityChecker: POSTabVisibilityCheckerProtocol {
    var initialVisibility: Bool = false
    var visibility: Bool = false

    /// When `true`, `checkVisibility` suspends until the surrounding task is cancelled before
    /// returning `visibility`, mimicking the real checker's site-settings wait being cut short
    /// by cancellation and resuming with an indeterminate verdict.
    var resolvesVisibilityOnlyOnCancellation: Bool = false

    private(set) var visibilityCheckStarted = false
    private(set) var visibilityCheckResolved = false

    func checkInitialVisibility() -> Bool {
        initialVisibility
    }

    @MainActor
    func checkVisibility() async -> Bool {
        visibilityCheckStarted = true
        if resolvesVisibilityOnlyOnCancellation {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
        }
        visibilityCheckResolved = true
        return visibility
    }
}
