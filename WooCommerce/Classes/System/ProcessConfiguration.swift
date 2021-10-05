import Foundation

struct ProcessConfiguration {
    static var shouldUseScreenshotsNetworkLayer: Bool {
        ProcessInfo.processInfo.arguments.contains("mocked-network-layer")
    }

    static var shouldLogoutAtLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("logout-at-launch")
    }

    static var shouldDisableAnimations: Bool {
        ProcessInfo.processInfo.arguments.contains("disable-animations")
    }
}
