import Foundation
import struct Yosemite.SiteSetting
import enum Yosemite.SettingAction
import enum Yosemite.Plugin
import class Yosemite.PluginsService
import Observation

@Observable final class PointOfSaleSettingsService {
    private let siteID: Int64
    private(set) var storeName: String

    private(set) var receiptStoreName: String?
    private(set) var receiptStoreAddress: String?
    private(set) var receiptStorePhone: String?
    private(set) var receiptStoreEmail: String?
    private(set) var receiptRefundReturnsPolicy: String?
    private(set) var isLoading: Bool = false
    private(set) var shouldShowReceiptInformation: Bool = false

    init(siteID: Int64, storeName: String) {
        self.siteID = siteID
        self.storeName = storeName
    }

    var storeAddress: String {
        SiteAddress().address
    }

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
                    updateReceiptSettings(from: siteSettings)
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
    private func isPluginSupported(_ plugin: Plugin, minimumVersion: String) async -> Bool {
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

    private func updateReceiptSettings(from siteSettings: [SiteSetting]) {
        receiptStoreName = settingValue(from: siteSettings, settingID: "woocommerce_pos_store_name")
        receiptStoreAddress = settingValue(from: siteSettings, settingID: "woocommerce_pos_store_address")
        receiptStorePhone = settingValue(from: siteSettings, settingID: "woocommerce_pos_store_phone")
        receiptStoreEmail = settingValue(from: siteSettings, settingID: "woocommerce_pos_store_email")
        receiptRefundReturnsPolicy = settingValue(from: siteSettings, settingID: "woocommerce_pos_refund_returns_policy")
    }

    private func settingValue(from siteSettings: [SiteSetting], settingID: String) -> String? {
        let value = siteSettings.first { $0.settingID == settingID }?.value
        return value?.isEmpty == true ? nil : value
    }
}
