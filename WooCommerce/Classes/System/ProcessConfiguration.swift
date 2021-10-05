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
}
