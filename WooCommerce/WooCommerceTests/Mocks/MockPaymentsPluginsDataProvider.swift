
import Foundation
import Yosemite
@testable import WooCommerce

final class MockCardPresentPluginsDataProvider: CardPresentPluginsDataProviderProtocol {
    private let wcPayPlugin: SystemPlugin?
    private let stripePlugin: SystemPlugin?
    private let bothPluginsInstalledAndActive: Bool
    private let wcPayInstalledAndActive: Bool
    private let stripeInstalledAndActive: Bool
    private let isWCPayVersionSupported: Bool
    private let isStripeVersionSupported: Bool

    init(wcPayPlugin: SystemPlugin? = nil,
         stripePlugin: SystemPlugin? = nil,
         bothPluginsInstalledAndActive: Bool = false,
         wcPayInstalledAndActive: Bool = false,
         stripeInstalledAndActive: Bool = false,
         isWCPayVersionSupported: Bool = false,
         isStripeVersionSupported: Bool = false) {
        self.wcPayPlugin = wcPayPlugin
        self.stripePlugin = stripePlugin
        self.bothPluginsInstalledAndActive = bothPluginsInstalledAndActive
        self.wcPayInstalledAndActive = wcPayInstalledAndActive
        self.stripeInstalledAndActive = stripeInstalledAndActive
        self.isWCPayVersionSupported = isWCPayVersionSupported
        self.isStripeVersionSupported = isStripeVersionSupported
    }


    func getWCPayPlugin() -> SystemPlugin? {
        wcPayPlugin
    }

    func getStripePlugin() -> SystemPlugin? {
        stripePlugin
    }

    func bothPluginsInstalledAndActive(wcPay: SystemPlugin?, stripe: SystemPlugin?) -> Bool {
        bothPluginsInstalledAndActive
    }

    func wcPayInstalledAndActive(wcPay: SystemPlugin?) -> Bool {
        wcPayInstalledAndActive
    }

    func stripeInstalledAndActive(stripe: SystemPlugin?) -> Bool {
        stripeInstalledAndActive
    }

    func isWCPayVersionSupported(plugin: SystemPlugin) -> Bool {
        isWCPayVersionSupported
    }

    func isStripeVersionSupported(plugin: SystemPlugin) -> Bool {
        isStripeVersionSupported
    }
}
