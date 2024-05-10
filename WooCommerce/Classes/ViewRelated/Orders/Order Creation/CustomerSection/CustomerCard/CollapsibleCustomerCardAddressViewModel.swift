import SwiftUI

/// View model for `CollapsibleCustomerCardAddressView`.
final class CollapsibleCustomerCardAddressViewModel: ObservableObject {
    let state: CollapsibleCustomerCardAddressView.State
    let editAddress: () -> Void

    init(billingAddressFormatted: String?,
         shippingAddressFormatted: String?,
         editAddress: @escaping () -> Void) {
        self.state = {
            guard !billingAddressFormatted.isNilOrEmpty || !shippingAddressFormatted.isNilOrEmpty else {
                return .addAddress
            }
            if billingAddressFormatted == shippingAddressFormatted {
                return .sameBillingAndShippingAddress(address: billingAddressFormatted ?? "")
            }
            if let billingAddressFormatted, billingAddressFormatted.isNotEmpty {
                if let shippingAddressFormatted, shippingAddressFormatted.isNotEmpty {
                    return .differentBillingAndShippingAddresses(billing: billingAddressFormatted, shipping: shippingAddressFormatted)
                } else {
                    return .billingOnly(address: billingAddressFormatted)
                }
            } else if let shippingAddressFormatted, shippingAddressFormatted.isNotEmpty {
                if let billingAddressFormatted, billingAddressFormatted.isNotEmpty {
                    return .differentBillingAndShippingAddresses(billing: billingAddressFormatted, shipping: shippingAddressFormatted)
                } else {
                    return .shippingOnly(address: shippingAddressFormatted)
                }
            } else {
                return .addAddress
            }
        }()
        self.editAddress = editAddress
    }
}
