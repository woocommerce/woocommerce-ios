import Foundation
import Yosemite

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

    /// Returns `true` when POS should use deterministic mocks for UI tests.
    static var shouldUsePOSUITestMocks: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("use-pos-ui-test-mocks")
        #else
        false
        #endif
    }

    /// Returns `true` when POS UI tests should force the POS tab visible regardless of rollout eligibility.
    static var shouldBypassPOSTabVisibilityChecks: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("bypass-pos-tab-visibility-checks")
        #else
        false
        #endif
    }

    /// Returns `true` when POS order syncing should be bypassed for screenshot tests.
    static var shouldBypassPOSOrderSyncing: Bool {
        ProcessInfo.processInfo.arguments.contains("bypass-pos-order-syncing")
    }

    /// Returns `true` when card present payment service should be mocked for screenshot tests.
    static var shouldUseMockCardPresentPayment: Bool {
        ProcessInfo.processInfo.arguments.contains("use-mocked-card-present-payment")
    }

    #if DEBUG
    /// Credentials to auto-authenticate with at launch, for local debugging against a real store
    /// (e.g. a Jurassic Ninja site) without going through the login UI. Only ever populated when
    /// running a DEBUG build with the required environment variables set on a personal Xcode scheme
    /// or `simctl launch` invocation — never checked into the repo.
    static var debugAutoLoginCredentials: Credentials? {
        let env = ProcessInfo.processInfo.environment
        guard let username = env["DEBUG_LOGIN_USERNAME"],
              let secret = env["DEBUG_LOGIN_SECRET"],
              let siteAddress = env["DEBUG_LOGIN_SITE_ADDRESS"] else {
            return nil
        }
        switch env["DEBUG_LOGIN_AUTH_TYPE"] {
        case "wpcom":
            return .wpcom(username: username, authToken: secret, siteAddress: siteAddress)
        default:
            return .applicationPassword(username: username, password: secret, siteAddress: siteAddress)
        }
    }

    /// Store ID to select alongside `debugAutoLoginCredentials`. Defaults to the self-hosted
    /// placeholder ID, which is correct for application-password logins.
    static var debugAutoLoginStoreID: Int64 {
        ProcessInfo.processInfo.environment["DEBUG_LOGIN_STORE_ID"].flatMap(Int64.init) ?? WooConstants.placeholderStoreID
    }
    #endif
}
