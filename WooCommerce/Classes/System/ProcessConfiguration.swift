import Foundation

/// Provides process-based configurations for screenshot generation and UI tests.
struct ProcessConfiguration {
    /// Returns `true` when generating screenshots.
    static var shouldUseScreenshotsNetworkLayer: Bool {
        ProcessInfo.processInfo.arguments.contains("mocked-network-layer")
    }

    /// Returns `true` when testing login flow UI.
    static var shouldLogoutAtLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("logout-at-launch")
    }

    /// Returns `true` when generating screenshots and testing login flow UI.
    static var shouldDisableAnimations: Bool {
        ProcessInfo.processInfo.arguments.contains("disable-animations")
    }

    /// Returns `true` when wishing to simulate push notifications.
    static var shouldSimulatePushNotification: Bool {
        ProcessInfo.processInfo.arguments.contains("-mocks-push-notification")
    }

    /// Returns `true` when POS eligibility checks should be bypassed for screenshot tests.
    static var shouldBypassPOSEligibilityChecks: Bool {
        ProcessInfo.processInfo.arguments.contains("bypass-pos-eligibility-checks")
    }

    /// Returns `true` when we load mocked POS products for screenshot tests.
    static var shouldLoadMockedPOSProducts: Bool {
        ProcessInfo.processInfo.arguments.contains("load-mocked-pos-products")
    }

    /// Returns `true` when POS order syncing should be bypassed for screenshot tests.
    static var shouldBypassPOSOrderSyncing: Bool {
        ProcessInfo.processInfo.arguments.contains("bypass-pos-order-syncing")
    }

    /// Returns `true` when card present payment service should be mocked for screenshot tests.
    static var shouldUseMockCardPresentPayment: Bool {
        ProcessInfo.processInfo.arguments.contains("use-mocked-card-present-payment")
    }
}
