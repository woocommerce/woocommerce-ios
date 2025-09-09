import Foundation
import Observation
import protocol Experiments.FeatureFlagService
import protocol Yosemite.StoresManager
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.PluginsServiceProtocol
import struct Yosemite.Order
import enum Yosemite.Plugin
import protocol WooFoundation.Analytics
import class Yosemite.PluginsService

protocol POSReceiptControllerProtocol {
    func sendReceipt(orderID: Int64, recipientEmail: String) async throws
}

final class POSReceiptController: POSReceiptControllerProtocol {
    init(siteID: Int64,
         orderService: POSOrderServiceProtocol,
         receiptService: POSReceiptServiceProtocol,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         pluginsService: PluginsServiceProtocol = PluginsService(storageManager: ServiceLocator.storageManager)) {
        self.siteID = siteID
        self.orderService = orderService
        self.receiptService = receiptService
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.pluginsService = pluginsService
    }

    private let siteID: Int64
    private let orderService: POSOrderServiceProtocol
    private let receiptService: POSReceiptServiceProtocol
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService
    private let pluginsService: PluginsServiceProtocol

    @MainActor
    func sendReceipt(orderID: Int64, recipientEmail: String) async throws {
        var isEligibleForPOSReceipt: Bool?
        do {
            try await orderService.updatePOSOrder(orderID: orderID, recipientEmail: recipientEmail)

            let posReceiptEligibility: Bool
            if featureFlagService.isFeatureFlagEnabled(.pointOfSaleReceipts) {
                posReceiptEligibility = isPluginSupported(
                    .wooCommerce,
                    minimumVersion: POSReceiptEligibilityConstants.wcPluginMinimumVersion,
                    siteID: siteID
                )
            } else {
                posReceiptEligibility = false
            }
            isEligibleForPOSReceipt = posReceiptEligibility

            try await receiptService.sendReceipt(orderID: orderID, recipientEmail: recipientEmail, isEligibleForPOSReceipt: posReceiptEligibility)

            analytics.track(.receiptEmailSuccess, withProperties: ["eligible_for_pos_receipt": posReceiptEligibility])
        } catch {
            let properties = [
                "eligible_for_pos_receipt": isEligibleForPOSReceipt
            ].compactMapValues( { $0 })
            analytics.track(.receiptEmailFailed, properties: properties, error: error)
            throw error
        }
    }
}

private extension POSReceiptController {
    @MainActor
    func isPluginSupported(_ plugin: Plugin, minimumVersion: String, siteID: Int64) -> Bool {
        // Plugin must be installed and active
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true),
              systemPlugin.active else {
            return false
        }

        // If plugin version is higher than minimum required version, mark as eligible
        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion,
                                                            includesDevAndBetaVersions: true)
        return isSupported
    }
}

private extension POSReceiptController {
    enum POSReceiptEligibilityConstants {
        static let wcPluginMinimumVersion = "10.0.0"
    }
}
