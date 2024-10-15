import Foundation
import Yosemite
import WooFoundation

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    /// Address to ship from (store address), formatted for display.
    let originAddress: String

    /// Address to ship to (customer address), formatted for display and split into separate lines to allow additional formatting.
    let destinationAddressLines: [String]

    /// Shipping lines for the order, with formatted amount.
    let shippingLines: [WooShipping_ShippingLineViewModel]

    /// Whether to mark the order as complete after the label is purchased.
    @Published var markOrderComplete: Bool = false

    /// Closure to execute after the label is successfully purchased.
    let onLabelPurchase: ((_ markOrderComplete: Bool) -> Void)?

    init(order: Order,
         siteAddress: SiteAddress = SiteAddress(),
         onLabelPurchase: ((Bool) -> Void)? = nil) {
        self.items = WooShippingItemsViewModel(dataSource: DefaultWooShippingItemsDataSource(order: order))
        self.onLabelPurchase = onLabelPurchase
        self.originAddress = Self.formatOriginAddress(siteAddress: siteAddress)
        self.destinationAddressLines = (order.shippingAddress?.formattedPostalAddress ?? "").components(separatedBy: .newlines)
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0) })
    }

    /// Purchases a shipping label with the provided label details and settings.
    func purchaseLabel() {
        // TODO: 13556 - Add action to purchase label remotely
        onLabelPurchase?(markOrderComplete) // TODO: 13556 - Only call this closure if the remote purchase is successful
    }
}

private extension WooShippingCreateLabelsViewModel {
    /// Formats the origin address from the provided `SiteAddress`.
    static func formatOriginAddress(siteAddress: SiteAddress) -> String {
        let address = Address(firstName: "",
                              lastName: "",
                              company: nil,
                              address1: siteAddress.address,
                              address2: siteAddress.address2,
                              city: siteAddress.city,
                              state: siteAddress.state,
                              postcode: siteAddress.postalCode,
                              country: siteAddress.countryCode.rawValue,
                              phone: nil,
                              email: nil)
        let formattedPostalAddress = address.formattedPostalAddress?.replacingOccurrences(of: "\n", with: ", ")
        return formattedPostalAddress ?? ""
    }
}
