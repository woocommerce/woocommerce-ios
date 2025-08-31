import SwiftUI
import protocol Yosemite.PluginsServiceProtocol
import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import enum Yosemite.Plugin
import struct Yosemite.SiteSetting

final class POSSettingsStoreViewModel: ObservableObject {
    @Published var receiptInformation = POSReceiptInformation.empty
    @Published var shouldShowReceiptInformation: Bool = false

    private let siteID: Int64
    private let settingsService: PointOfSaleSettingsServiceProtocol
    private let pluginsService: PluginsServiceProtocol
    private let defaultSiteName: String?
    private let siteSettings: [SiteSetting]

    init(siteID: Int64,
         settingsService: PointOfSaleSettingsServiceProtocol,
         pluginsService: PluginsServiceProtocol,
         defaultSiteName: String?,
         siteSettings: [SiteSetting]) {
        self.siteID = siteID
        self.settingsService = settingsService
        self.pluginsService = pluginsService
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
        shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: Constants.minimumWooCommerceVersion)

        guard shouldShowReceiptInformation else {
            return
        }
        do {
            let siteSettings = try await settingsService.retrievePointOfSaleSettings()
            updateReceiptSettings(from: siteSettings)
        } catch {
            DDLogError("Failed to load POS settings: \(error)")
        }
    }

    @MainActor
    private func isPluginSupported(_ plugin: Plugin,
                                   minimumVersion: String) async -> Bool {
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true), systemPlugin.active else {
            return false
        }

        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion)
        return isSupported
    }

    private func updateReceiptSettings(from siteSettings: [SiteSetting]) {
        receiptInformation = POSReceiptInformation(
            storeName: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_name"),
            storeAddress: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_address"),
            phone: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_phone"),
            email: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_email"),
            refundReturnsPolicy: settingValue(from: siteSettings, settingID: "woocommerce_pos_refund_returns_policy")
        )
    }

    private func settingValue(from siteSettings: [SiteSetting], settingID: String) -> String? {
        let value = siteSettings.first { $0.settingID == settingID }?.value
        return value?.isEmpty == true ? nil : value
    }
}

private extension POSSettingsStoreViewModel {
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
