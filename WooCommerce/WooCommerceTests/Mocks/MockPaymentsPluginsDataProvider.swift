
import Foundation
import Yosemite
@testable import WooCommerce

final class MockCardPresentPluginsDataProvider: CardPresentPluginsDataProviderProtocol {
    private let wcPayPlugin: SystemPlugin?
    private let stripePlugin: SystemPlugin?
    private let paymentPluginsInstalledAndActiveStatus: PaymentPluginsInstalledAndActiveStatus
    private let isWCPayVersionSupported: Bool
    private let isStripeVersionSupported: Bool

    init(wcPayPlugin: SystemPlugin? = nil,
         stripePlugin: SystemPlugin? = nil,
         paymentPluginsInstalledAndActiveStatus: PaymentPluginsInstalledAndActiveStatus = .noneAreInstalledAndActive,
         isWCPayVersionSupported: Bool = false,
         isStripeVersionSupported: Bool = false) {
        self.wcPayPlugin = wcPayPlugin
        self.stripePlugin = stripePlugin
        self.paymentPluginsInstalledAndActiveStatus = paymentPluginsInstalledAndActiveStatus
        self.isWCPayVersionSupported = isWCPayVersionSupported
        self.isStripeVersionSupported = isStripeVersionSupported
    }


    func getWCPayPlugin() -> SystemPlugin? {
        wcPayPlugin
    }

    func getStripePlugin() -> SystemPlugin? {
        stripePlugin
    }

    func paymentPluginsInstalledAndActiveStatus(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin?) -> PaymentPluginsInstalledAndActiveStatus {
        paymentPluginsInstalledAndActiveStatus
    }

    func isWCPayVersionSupported(plugin: SystemPlugin) -> Bool {
        isWCPayVersionSupported
    }

    func isStripeVersionSupported(plugin: SystemPlugin) -> Bool {
        isStripeVersionSupported
    }
}
