import Testing
import GameController
@testable import PointOfSale

@MainActor
struct GameControllerBarcodeObserverTests {

    /// Verifies that destroying an older observer does not nil out the keyChangedHandler
    /// set by a newer observer on the shared GCKeyboard.coalesced keyboard.
    ///
    /// This is the exact scenario that caused barcode scanning to stop working after
    /// completing a payment in POS: the payment success screen and item list both have
    /// barcode scanning, and during the SwiftUI transition the old observer's cleanup
    /// was destroying the new observer's handler.
    @Test("Destroying an older observer preserves a newer observer's keyboard handler")
    func destroying_older_observer_preserves_newer_observers_keyboard_handler() {
        guard let keyboard = GCKeyboard.coalesced,
              let input = keyboard.keyboardInput else {
            return // No keyboard available in this environment
        }

        // Given — two observers created in sequence (simulating overlapping barcode scanners)
        var observerA: GameControllerBarcodeObserver? = GameControllerBarcodeObserver(
            analytics: MockPOSAnalytics(),
            onScan: { _ in }
        )
        _ = observerA // suppress unused warning

        let observerB = GameControllerBarcodeObserver(
            analytics: MockPOSAnalytics(),
            onScan: { _ in }
        )

        // Observer B should now own the handler
        #expect(input.keyChangedHandler != nil)

        // When — destroy the older observer (simulates payment success view disappearing)
        observerA = nil

        // Then — the newer observer's handler should still be set
        #expect(input.keyChangedHandler != nil)

        _ = observerB // keep alive
    }

    /// Verifies that destroying the last active observer properly cleans up the handler.
    @Test("Destroying the only active observer clears the keyboard handler")
    func destroying_only_observer_clears_keyboard_handler() {
        guard let keyboard = GCKeyboard.coalesced,
              let input = keyboard.keyboardInput else {
            return // No keyboard available in this environment
        }

        // Given — a single observer
        var observer: GameControllerBarcodeObserver? = GameControllerBarcodeObserver(
            analytics: MockPOSAnalytics(),
            onScan: { _ in }
        )

        #expect(input.keyChangedHandler != nil)

        // When — destroy it
        observer = nil

        // Then — handler should be cleaned up
        #expect(input.keyChangedHandler == nil)

        _ = observer // suppress unused warning
    }
}
