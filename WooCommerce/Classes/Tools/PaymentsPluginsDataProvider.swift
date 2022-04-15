import Yosemite
import Foundation
import Storage

/// Provides data and helper methods related to the Payments Plugins (WCPay, Stripe).
/// It extracts the information from the provided `StorageManagerType`, but please notice that it does not
/// take care of syncing the data, so it should be done beforehand.
///
protocol CardPresentPluginsDataProviderProtocol {
    func getWCPayPlugin() -> Yosemite.SystemPlugin?
    func getStripePlugin() -> Yosemite.SystemPlugin?
    func bothPluginsInstalledAndActive(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin?) -> Bool
    func wcPayInstalledAndActive(wcPay: Yosemite.SystemPlugin?) -> Bool
    func stripeInstalledAndActive(stripe: Yosemite.SystemPlugin?) -> Bool
    func isWCPayVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool
    func isStripeVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool
}

struct CardPresentPluginsDataProvider: CardPresentPluginsDataProviderProtocol {
    private let storageManager: StorageManagerType
    private let stores: StoresManager
    private let configuration: CardPresentPaymentsConfiguration

    init(
        storageManager: StorageManagerType = ServiceLocator.storageManager,
        stores: StoresManager = ServiceLocator.stores,
        configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader(stores: ServiceLocator.stores).configuration
    ) {
        self.storageManager = storageManager
        self.stores = stores
        self.configuration = configuration
    }

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    func getWCPayPlugin() -> Yosemite.SystemPlugin? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadSystemPlugin(siteID: siteID, name: CardPresentPaymentsPlugins.wcPay.pluginName)?
            .toReadOnly()
    }

    func getStripePlugin() -> Yosemite.SystemPlugin? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadSystemPlugin(siteID: siteID, name: CardPresentPaymentsPlugins.stripe.pluginName)?
            .toReadOnly()
    }

    func bothPluginsInstalledAndActive(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin?) -> Bool {
        guard let wcPay = wcPay, let stripe = stripe else {
            return false
        }

        return wcPay.active && stripe.active
    }

    func wcPayInstalledAndActive(wcPay: Yosemite.SystemPlugin?) -> Bool {
        // If the WCPay plugin is not installed, immediately return false
        guard let wcPay = wcPay else {
            return false
        }

        return wcPay.active
    }

    func stripeInstalledAndActive(stripe: Yosemite.SystemPlugin?) -> Bool {
        // If the Stripe plugin is not installed, immediately return false
        guard let stripe = stripe else {
            return false
        }

        return stripe.active
    }

    func isWCPayVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        isPluginVersionSupported(plugin: plugin, paymentPlugin: .wcPay)
    }

    func isStripeVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        isPluginVersionSupported(plugin: plugin, paymentPlugin: .stripe)
    }

    private func isPluginVersionSupported(plugin: Yosemite.SystemPlugin,
                                          paymentPlugin: CardPresentPaymentsPlugins) -> Bool {
        guard let pluginSupport = configuration.supportedPluginVersions.first(where: { support in
            support.plugin == paymentPlugin
        }) else {
            return false
        }
        return VersionHelpers.isVersionSupported(version: plugin.version,
                                                 minimumRequired: pluginSupport.minimumVersion)
    }
}
