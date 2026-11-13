import Testing
import UIKit
import GameController
@testable import PointOfSale

@MainActor
struct BarcodeScannerContainerTests {
    @Test
    func test_container_when_acceptance_changes_then_existing_observer_uses_current_value() throws {
        // Given
        let analytics = MockPOSAnalytics()
        var results: [Result<String, HIDBarcodeParserError>] = []
        let container = GameControllerBarcodeScannerHostingController(
            configuration: .default,
            analytics: analytics,
            onScan: { results.append($0) },
            voiceOverStateProvider: MockVoiceOverStateProvider(isRunning: true))
        show(container)
        let observer = try #require(container.uiKitObserver)
        observer.processUIPress([])
        let parser = try #require(observer.barcodeParser)

        // When: SwiftUI updates the acceptance check while the observer is still installed.
        container.isScanningEnabled = { false }
        for key: GCKeyCode in [.one, .two, .three, .four, .five, .six, .returnOrEnter] {
            parser.processKeyPress(key)
        }

        // Then
        #expect(results.isEmpty)
        #expect(analytics.events.isEmpty)

        container.isScanningEnabled = { true }
        for key: GCKeyCode in [.one, .two, .three, .four, .five, .six, .returnOrEnter] {
            parser.processKeyPress(key)
        }
        #expect(results.count == 1)
        #expect(analytics.events.count == 1)
    }

    @Test("Container uses GameController observer when VoiceOver is disabled")
    func container_when_voiceover_disabled_uses_gamecontroller_observer() {
        // Given
        let mockProvider = MockVoiceOverStateProvider(isRunning: false)
        let container = GameControllerBarcodeScannerHostingController(
            configuration: .default,
            analytics: MockPOSAnalytics(),
            onScan: { _ in },
            voiceOverStateProvider: mockProvider
        )
        show(container)

        // Then - Should have GameController observer
        #expect(container.gameControllerObserver != nil)
        #expect(container.uiKitObserver == nil)
    }

    @Test("Container uses UIKit observer when VoiceOver is enabled")
    func container_when_voiceover_enabled_uses_uikit_observer() {
        // Given
        let mockProvider = MockVoiceOverStateProvider(isRunning: true)
        let container = GameControllerBarcodeScannerHostingController(
            configuration: .default,
            analytics: MockPOSAnalytics(),
            onScan: { _ in },
            voiceOverStateProvider: mockProvider
        )
        show(container)

        // Then - Should have UIKit observer
        #expect(container.gameControllerObserver == nil)
        #expect(container.uiKitObserver != nil)
    }

    @Test("Container switches observers when VoiceOver state changes")
    func container_when_voiceover_state_changes_switches_observers() {
        // Given
        let mockProvider = MockVoiceOverStateProvider(isRunning: false)
        let container = GameControllerBarcodeScannerHostingController(
            configuration: .default,
            analytics: MockPOSAnalytics(),
            onScan: { _ in },
            voiceOverStateProvider: mockProvider
        )
        show(container)

        // When - Initially should use GameController
        #expect(container.gameControllerObserver != nil && container.uiKitObserver == nil)

        // Enable VoiceOver and post notification
        mockProvider.isRunning = true
        NotificationCenter.default.post(
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )

        // Then - Should switch to UIKit observer
        #expect(container.gameControllerObserver == nil && container.uiKitObserver != nil)

        // Disable VoiceOver and post notification again
        mockProvider.isRunning = false
        NotificationCenter.default.post(
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )

        // Then - Should switch back to GameController observer
        #expect(container.gameControllerObserver != nil && container.uiKitObserver == nil)
    }

    @Test("Container properly cleans up observers when switching")
    func container_when_switching_observers_cleans_up_properly() {
        // Given
        let mockProvider = MockVoiceOverStateProvider(isRunning: false)
        let container = GameControllerBarcodeScannerHostingController(
            configuration: .default,
            analytics: MockPOSAnalytics(),
            onScan: { _ in },
            voiceOverStateProvider: mockProvider
        )
        show(container)

        // When - Switch between observers multiple times
        #expect(container.gameControllerObserver != nil && container.uiKitObserver == nil)

        mockProvider.isRunning = true
        NotificationCenter.default.post(
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        #expect(container.gameControllerObserver == nil && container.uiKitObserver != nil)

        mockProvider.isRunning = false
        NotificationCenter.default.post(
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        #expect(container.gameControllerObserver != nil && container.uiKitObserver == nil)

        mockProvider.isRunning = true
        NotificationCenter.default.post(
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        #expect(container.gameControllerObserver == nil && container.uiKitObserver != nil)

        // Then - Should end up with the correct final observer
        #expect(container.gameControllerObserver == nil && container.uiKitObserver != nil)
    }

    @Test("Container only observes keyboard input while visible")
    func container_starts_and_stops_observers_with_view_appearance() {
        // Given
        let container = GameControllerBarcodeScannerHostingController(
            configuration: .default,
            analytics: MockPOSAnalytics(),
            onScan: { _ in },
            voiceOverStateProvider: MockVoiceOverStateProvider(isRunning: false)
        )

        // Then
        #expect(container.gameControllerObserver == nil)
        #expect(container.uiKitObserver == nil)

        // When
        show(container)

        // Then
        #expect(container.gameControllerObserver != nil)
        #expect(container.uiKitObserver == nil)

        // When
        hide(container)

        // Then
        #expect(container.gameControllerObserver == nil)
        #expect(container.uiKitObserver == nil)
    }

    private func show(_ container: UIViewController) {
        container.beginAppearanceTransition(true, animated: false)
        container.endAppearanceTransition()
    }

    private func hide(_ container: UIViewController) {
        container.beginAppearanceTransition(false, animated: false)
        container.endAppearanceTransition()
    }
}

// MARK: - Mock Classes for Testing

private class MockVoiceOverStateProvider: VoiceOverStateProvider {
    var isRunning: Bool

    init(isRunning: Bool) {
        self.isRunning = isRunning
    }

    var isVoiceOverRunning: Bool {
        return isRunning
    }
}
