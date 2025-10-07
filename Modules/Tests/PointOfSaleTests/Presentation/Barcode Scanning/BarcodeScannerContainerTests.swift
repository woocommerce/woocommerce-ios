import Testing
import UIKit
@testable import PointOfSale

@MainActor
struct BarcodeScannerContainerTests {
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
