import Yosemite
import Foundation
import Storage

/// Provides information about which of the payment plugins (WCPay and Stripe) are installed and active
///
enum PaymentPluginsInstalledAndActiveStatus {
    // None is neither installed nor active
    case noneAreInstalledAndActive
    // Only WCPay is installed and active simultaneously
    case onlyWCPayIsInstalledAndActive
    // Only Stripe is installed and active simultaneously
    case onlyStripeIsInstalledAndActive
    // Both are installed and active
    case bothAreInstalledAndActive
}

/// Provides data and helper methods related to the Payments Plugins (WCPay, Stripe).
/// It extracts the information from the provided `StorageManagerType`, but please notice that it does not
/// take care of syncing the data, so it should be done beforehand.
///
protocol CardPresentPluginsDataProviderProtocol {
    func getWCPayPlugin() -> Yosemite.SystemPlugin?
    func getStripePlugin() -> Yosemite.SystemPlugin?
    func paymentPluginsInstalledAndActiveStatus(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin?) -> PaymentPluginsInstalledAndActiveStatus
    func isWCPayVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool
    func isStripeVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool
}

struct CardPresentPluginsDataProvider: CardPresentPluginsDataProviderProtocol {
    private let storageManager: StorageManagerType
    private let stores: StoresManager
    private let configurationLoader: CardPresentConfigurationLoader

    init(
        storageManager: StorageManagerType = ServiceLocator.storageManager,
        stores: StoresManager = ServiceLocator.stores,
        configurationLoader: CardPresentConfigurationLoader
    ) {
        self.storageManager = storageManager
        self.stores = stores
        self.configurationLoader = configurationLoader
    }

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    func getWCPayPlugin() -> Yosemite.SystemPlugin? {
        getSystemPlugin(from: .wcPay)
    }

    func getStripePlugin() -> Yosemite.SystemPlugin? {
        getSystemPlugin(from: .stripe)
    }

    func paymentPluginsInstalledAndActiveStatus(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin?) -> PaymentPluginsInstalledAndActiveStatus {
        let wcPayInstalledAndActive = wcPay?.active ?? false
        let stripeInstalledAndActive = stripe?.active ?? false

        switch (wcPayInstalledAndActive, stripeInstalledAndActive) {
        case (false, false):
            return .noneAreInstalledAndActive
        case (false, true):
            return .onlyStripeIsInstalledAndActive
        case (true, false):
            return .onlyWCPayIsInstalledAndActive
        case (true, true):
            return .bothAreInstalledAndActive
        }
    }

    func isWCPayVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        isPluginVersionSupported(plugin: plugin, paymentPlugin: .wcPay)
    }

    func isStripeVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        isPluginVersionSupported(plugin: plugin, paymentPlugin: .stripe)
    }

    private func isPluginVersionSupported(plugin: Yosemite.SystemPlugin,
                                          paymentPlugin: CardPresentPaymentsPlugin) -> Bool {
        guard let pluginSupport = configurationLoader.configuration.supportedPluginVersions.first(where: { support in
            support.plugin == paymentPlugin
        }) else {
            return false
        }
        return VersionHelpers.isVersionSupported(version: plugin.version,
                                                 minimumRequired: pluginSupport.minimumVersion)
    }

    private func getSystemPlugin(from configuration: CardPresentPaymentsPlugin) -> Yosemite.SystemPlugin? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadSystemPlugins(siteID: siteID).map { $0.toReadOnly() }
            .first(where: { $0.fileNameWithoutExtension == configuration.fileNameWithoutExtension })
    }
}

extension Yosemite.SystemPlugin {
    var fileNameWithoutExtension: String {
        ((plugin as NSString).lastPathComponent as NSString).deletingPathExtension
    }
}
