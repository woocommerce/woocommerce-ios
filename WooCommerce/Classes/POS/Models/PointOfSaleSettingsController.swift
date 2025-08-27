import Foundation
import struct Yosemite.SiteSetting
import enum Yosemite.Plugin
import class Yosemite.PluginsService
import Observation

import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import class Yosemite.PointOfSaleSettingsService
import Storage

protocol PointOfSaleSettingsControllerProtocol {
    var receiptStoreName: String? { get }
    var receiptStoreAddress: String? { get }
    var receiptStorePhone: String? { get }
    var receiptStoreEmail: String? { get }
    var receiptRefundReturnsPolicy: String? { get }
    var isLoading: Bool { get }
    var shouldShowReceiptInformation: Bool { get }
    var storeName: String { get }
    var storeAddress: String { get }

    func retrievePOSReceiptSettings() async
}

@Observable final class PointOfSaleSettingsController: PointOfSaleSettingsControllerProtocol {
    private(set) var receiptStoreName: String?
    private(set) var receiptStoreAddress: String?
    private(set) var receiptStorePhone: String?
    private(set) var receiptStoreEmail: String?
    private(set) var receiptRefundReturnsPolicy: String?
    private(set) var isLoading: Bool = false
    private(set) var shouldShowReceiptInformation: Bool = false

    private let defaultSiteName: String?
    private let settingsService: PointOfSaleSettingsServiceProtocol
    private let siteSettings: [SiteSetting]

    init(settingsService: PointOfSaleSettingsServiceProtocol,
         defaultSiteName: String? = ServiceLocator.stores.sessionManager.defaultSite?.name,
         siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings) {
        self.settingsService = settingsService
        self.defaultSiteName = defaultSiteName
        self.siteSettings = siteSettings
    }

    var storeName: String {
        if let defaultSiteName {
            return defaultSiteName
        } else {
            return Localization.storeNameNotSet
        }
    }

    var storeAddress: String {
        SiteAddress(siteSettings: siteSettings).address
    }

    @MainActor
    func retrievePOSReceiptSettings() async {
        isLoading = true

        shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: Constants.minimumWooCommerceVersion)

        guard shouldShowReceiptInformation else {
            isLoading = false
            return
        }

        do {
            let siteSettings = try await settingsService.retrievePointOfSaleSettings()
            updateReceiptSettings(from: siteSettings)
        } catch {
            DDLogError("Failed to load POS settings: \(error)")
        }
        isLoading = false
    }

    @MainActor
    private func isPluginSupported(_ plugin: Plugin,
                                   storageManager: StorageManagerType = ServiceLocator.storageManager,
                                   minimumVersion: String) async -> Bool {
        let pluginsService = PluginsService(storageManager: storageManager)
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: settingsService.siteID, plugin: plugin, isActive: true), systemPlugin.active else {
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

private extension PointOfSaleSettingsController {
    enum Constants {
        static let minimumWooCommerceVersion: String = "10.0"
    }

    enum Localization {
        static let storeNameNotSet = NSLocalizedString(
            "pointOfSaleSettingsService.storeNameNotSet",
            value: "Not set",
            comment: "Text displayed on Point of Sale settings when store has not been provided."
        )
    }
}

#if DEBUG
final class PointOfSaleSettingsPreviewController: PointOfSaleSettingsControllerProtocol {
    var receiptStoreName: String? = "Sample Store"
    var receiptStoreAddress: String? = "123 Main Street\nAnytown, ST 12345"
    var receiptStorePhone: String? = "+1 (555) 123-4567"
    var receiptStoreEmail: String? = "store@example.com"
    var receiptRefundReturnsPolicy: String? = "30-day return policy"
    var isLoading: Bool = false
    var shouldShowReceiptInformation: Bool = true
    var storeName: String = "Sample Store"

    var storeAddress: String {
        "123 Main Street\nAnytown, ST 12345"
    }

    func retrievePOSReceiptSettings() async {
        // no-op
    }
}
#endif
