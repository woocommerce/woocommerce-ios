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

    init(
        storageManager: StorageManagerType = ServiceLocator.storageManager,
        stores: StoresManager = ServiceLocator.stores
    ) {
        self.storageManager = storageManager
        self.stores = stores
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
        VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: CardPresentPaymentsPlugins.wcPay.minimumSupportedPluginVersion)
    }

    func isStripeVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: CardPresentPaymentsPlugins.stripe.minimumSupportedPluginVersion)
    }
}
