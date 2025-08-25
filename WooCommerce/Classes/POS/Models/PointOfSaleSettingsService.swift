import Yosemite
import Observation

@Observable final class PointOfSaleSettingsService {
    private(set) var receiptStoreName: String = "Not set"
    private(set) var receiptStoreAddress: String = "Not set"
    private(set) var receiptStorePhone: String = "Not set"
    private(set) var receiptStoreEmail: String = "Not set"
    private(set) var receiptRefundReturnsPolicy: String = "Not set"
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
    func loadSettings() async {
        isLoading = true

        shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: "10.0")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let action = SettingAction.retrievePointOfSaleSettings(siteID: siteID) { [weak self] result in
                switch result {
                case .success(let siteSettings):
                    self?.receiptStoreName = siteSettings.first { $0.settingID == "woocommerce_pos_store_name" }?.value ?? "Not set"
                    self?.receiptStoreAddress = siteSettings.first { $0.settingID == "woocommerce_pos_store_address" }?.value ?? "Not set"
                    self?.receiptStorePhone = siteSettings.first { $0.settingID == "woocommerce_pos_store_phone" }?.value ?? "Not set"
                    self?.receiptStoreEmail = siteSettings.first { $0.settingID == "woocommerce_pos_store_email" }?.value ?? "Not set"
                    self?.receiptRefundReturnsPolicy = siteSettings.first { $0.settingID == "woocommerce_pos_refund_returns_policy" }?.value ?? "Not set"
                case .failure(let error):
                    DDLogError("Failed to load POS settings: \(error)")
                }
                self?.isLoading = false
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
