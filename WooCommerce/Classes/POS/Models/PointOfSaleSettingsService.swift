import Yosemite

final class PointOfSaleSettingsService {
    let receiptStoreName: String
    let receiptStoreAddress: String
    let receiptStorePhone: String
    let receiptStoreEmail: String
    let receiptRefundReturnsPolicy: String

    var storeName: String {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return "Not set"
        }
        return site.name
    }

    var storeAddress: String {
        SiteAddress().address
    }

    var storeEmail: String {
        "Not set" // TBD
    }

    static let empty = PointOfSaleSettingsService(from: [])

    init(from siteSettings: [SiteSetting]) {
        self.receiptStoreName = siteSettings.first { $0.settingID == "woocommerce_pos_store_name" }?.value ?? "Not set"
        self.receiptStoreAddress = siteSettings.first { $0.settingID == "woocommerce_pos_store_address" }?.value ?? "Not set"
        self.receiptStorePhone = siteSettings.first { $0.settingID == "woocommerce_pos_store_phone" }?.value ?? "Not set"
        self.receiptStoreEmail = siteSettings.first { $0.settingID == "woocommerce_pos_store_email" }?.value ?? "Not set"
        self.receiptRefundReturnsPolicy = siteSettings.first { $0.settingID == "woocommerce_pos_refund_returns_policy" }?.value ?? "Not set"
    }

    @MainActor
    func isPluginSupported(_ plugin: Plugin, minimumVersion: String) async -> Bool {
        let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
        let storageManager = ServiceLocator.storageManager
        let pluginsService = PluginsService(storageManager: storageManager)
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true),
              systemPlugin.active else {
            return false
        }

        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion)
        return isSupported
    }
}
