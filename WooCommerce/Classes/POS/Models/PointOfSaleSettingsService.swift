import Yosemite
import Observation

@Observable final class PointOfSaleSettingsService {
    private(set) var receiptStoreName: String?
    private(set) var receiptStoreAddress: String?
    private(set) var receiptStorePhone: String?
    private(set) var receiptStoreEmail: String?
    private(set) var receiptRefundReturnsPolicy: String?
    private(set) var isLoading: Bool = false
    private(set) var shouldShowReceiptInformation: Bool = false

    var storeName: String {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return "Not set"
        }
        return site.name
    }

    var storeAddress: String {
        SiteAddress().address
    }

    private var siteID: Int64 {
        ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
    }

    static let empty = PointOfSaleSettingsService()

    init() { }

    @MainActor
    func retrievePOSReceiptSettings() async {
        isLoading = true

        shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: "10.0")

        guard shouldShowReceiptInformation else {
            isLoading = false
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let action = SettingAction.retrievePointOfSaleSettings(siteID: siteID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let siteSettings):
                    receiptStoreName = siteSettings.first { $0.settingID == "woocommerce_pos_store_name" }?.value
                    receiptStoreAddress = siteSettings.first { $0.settingID == "woocommerce_pos_store_address" }?.value
                    receiptStorePhone = siteSettings.first { $0.settingID == "woocommerce_pos_store_phone" }?.value
                    receiptStoreEmail = siteSettings.first { $0.settingID == "woocommerce_pos_store_email" }?.value
                    receiptRefundReturnsPolicy = siteSettings.first { $0.settingID == "woocommerce_pos_refund_returns_policy" }?.value
                case .failure(let error):
                    DDLogError("Failed to load POS settings: \(error)")
                }
                isLoading = false
                continuation.resume()
            }
            ServiceLocator.stores.dispatch(action)
        }
    }

    @MainActor
    func isPluginSupported(_ plugin: Plugin, minimumVersion: String) async -> Bool {
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
