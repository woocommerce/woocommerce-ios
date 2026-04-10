import Foundation
import Yosemite

extension ShippingLabel {
    /// Following logic in the plugin
    /// https://github.com/woocommerce/woocommerce-shipping/blob/0f67a1eb349cbe90ce471d88c7b31bd4950d6744/client/utils/label/refund.ts#L5
    var refundDuration: Int {
        carrierID == WooShippingCarrier.dhlExpress.rawValue ? 31 : 14
    }

    var hasExpired: Bool {
        if status == .anonymized || usedDate != nil {
            return true
        } else if let expiryDate, expiryDate < Date() {
            return true
        }
        return false
    }

    var isRefundable: Bool {
        let thirtyDaysAgo = Date(timeIntervalSinceNow: -86_400 * 30)
        if dateCreated < thirtyDaysAgo || hasExpired {
            return false
        } else if carrierID == WooShippingCarrier.usps.rawValue && trackingNumber.isEmpty {
            return false
        }
        return true
    }

    var hasCustomsForm: Bool {
        commercialInvoiceURL?.isNotEmpty == true
    }
}
