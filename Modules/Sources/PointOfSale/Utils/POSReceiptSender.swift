import Foundation
import protocol Yosemite.StoresManager
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.PluginsServiceProtocol
import struct Yosemite.Order
import enum Yosemite.Plugin
import protocol WooFoundation.Analytics
import class Yosemite.PluginsService
import WooFoundationCore

protocol POSReceiptSending {
    func sendReceipt(orderID: Int64, recipientEmail: String) async throws
}

final class POSReceiptSender: POSReceiptSending {
    init(siteID: Int64,
         orderService: POSOrderServiceProtocol,
         receiptService: POSReceiptServiceProtocol,
         analytics: POSAnalyticsProviding,
         pluginsService: PluginsServiceProtocol
    ) {
        self.siteID = siteID
        self.orderService = orderService
        self.receiptService = receiptService
        self.analytics = analytics
        self.pluginsService = pluginsService
    }

    private let siteID: Int64
    private let orderService: POSOrderServiceProtocol
    private let receiptService: POSReceiptServiceProtocol
    private let analytics: POSAnalyticsProviding
    private let pluginsService: PluginsServiceProtocol

    @MainActor
    func sendReceipt(orderID: Int64, recipientEmail: String) async throws {
        var isEligibleForPOSReceipt: Bool = false
        do {
            isEligibleForPOSReceipt = isPluginSupported(
                .wooCommerce,
                minimumVersion: POSReceiptEligibilityConstants.wcPluginMinimumVersion,
                siteID: siteID
            )

            // Only update order email for previous POS receipt API version
            // POS receipt now handles email update internally
            if !isEligibleForPOSReceipt {
                try await orderService.updatePOSOrder(orderID: orderID, recipientEmail: recipientEmail)
            }

            let supportsAutoTemplateSelection = isPluginSupported(
                .wooCommerce,
                minimumVersion: POSReceiptEligibilityConstants.wcAutoTemplateSelectionMinimumVersion,
                siteID: siteID
            )
            let templateID: String? = supportsAutoTemplateSelection ? nil : "customer_pos_completed_order"

            try await receiptService.sendReceipt(orderID: orderID,
                                                 recipientEmail: recipientEmail,
                                                 isEligibleForPOSReceipt: isEligibleForPOSReceipt,
                                                 templateID: templateID)

            analytics.track(.receiptEmailSuccess, parameters: ["eligible_for_pos_receipt": isEligibleForPOSReceipt])
        } catch {
            let properties = [
                "eligible_for_pos_receipt": isEligibleForPOSReceipt
            ]
            analytics.track(.receiptEmailFailed, parameters: properties, error: error)
            throw error
        }
    }
}

private extension POSReceiptSender {
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

private extension POSReceiptSender {
    enum POSReceiptEligibilityConstants {
        static let wcPluginMinimumVersion = "10.0.0"
        static let wcAutoTemplateSelectionMinimumVersion = "10.7.0-dev"
    }
}
