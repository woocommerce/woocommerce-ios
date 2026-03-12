import CocoaLumberjackSwift
import SwiftUI
import class Yosemite.SiteAddress
import protocol Yosemite.PluginsServiceProtocol
import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import enum Yosemite.Plugin
import enum Yosemite.POSReceiptField
import struct Yosemite.SiteSetting
import struct Yosemite.POSReceiptInformation
import WooFoundationCore

final class POSSettingsStoreViewModel: ObservableObject {
    @Published var receiptInformation = POSReceiptInformation.empty
    @Published var shouldShowReceiptInformation: Bool = false

    // MARK: - Editing state
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    @Published var saveError: String?
    @Published var editableStoreName: String = ""
    @Published var editableStoreAddress: String = ""
    @Published var editablePhone: String = ""
    @Published var editableEmail: String = ""
    @Published var editableRefundReturnsPolicy: String = ""

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
        let siteAddress = SiteAddress(siteSettings: siteSettings)
        let address1 = siteAddress.address
        let address2 = siteAddress.address2

        if address2.isEmpty {
            return address1
        } else {
            return "\(address1)\n\(address2)"
        }
    }

    var hasChanges: Bool {
        editableStoreName != (receiptInformation.storeName ?? "") ||
        editableStoreAddress != (receiptInformation.storeAddress ?? "") ||
        editablePhone != (receiptInformation.phone ?? "") ||
        editableEmail != (receiptInformation.email ?? "") ||
        editableRefundReturnsPolicy != (receiptInformation.refundReturnsPolicy ?? "")
    }

    func startEditing() {
        editableStoreName = receiptInformation.storeName ?? ""
        editableStoreAddress = receiptInformation.storeAddress ?? ""
        editablePhone = receiptInformation.phone ?? ""
        editableEmail = receiptInformation.email ?? ""
        editableRefundReturnsPolicy = receiptInformation.refundReturnsPolicy ?? ""
        saveError = nil
        isEditing = true
    }

    func cancelEditing() {
        isEditing = false
        saveError = nil
    }

    @MainActor
    func saveReceiptInformation() async {
        var changes: [POSReceiptField: String] = [:]

        if editableStoreName != (receiptInformation.storeName ?? "") {
            changes[.storeName] = editableStoreName
        }
        if editableStoreAddress != (receiptInformation.storeAddress ?? "") {
            changes[.storeAddress] = editableStoreAddress
        }
        if editablePhone != (receiptInformation.phone ?? "") {
            changes[.phone] = editablePhone
        }
        if editableEmail != (receiptInformation.email ?? "") {
            changes[.email] = editableEmail
        }
        if editableRefundReturnsPolicy != (receiptInformation.refundReturnsPolicy ?? "") {
            changes[.refundReturnsPolicy] = editableRefundReturnsPolicy
        }

        guard !changes.isEmpty else {
            isEditing = false
            return
        }

        isSaving = true
        saveError = nil

        do {
            receiptInformation = try await settingsService.updatePointOfSaleSettings(changes)
            isEditing = false
        } catch {
            DDLogError("Failed to save POS receipt settings: \(error)")
            saveError = Localization.saveErrorMessage
        }

        isSaving = false
    }

    @MainActor
    func retrievePOSReceiptSettings() async {
        shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: Constants.minimumWooCommerceVersion)

        guard shouldShowReceiptInformation else {
            return
        }
        do {
            receiptInformation = try await settingsService.retrievePointOfSaleSettings()
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

        static let saveErrorMessage = NSLocalizedString(
            "pointOfSaleSettingsStoreViewModel.saveError",
            value: "Failed to save receipt information. Please try again.",
            comment: "Error message displayed when saving POS receipt settings fails."
        )
    }
}
