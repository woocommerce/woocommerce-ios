import Foundation
import Yosemite
import WooFoundation

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter

    /// The purchased shipping label.
    @Published private var shippingLabel: ShippingLabel?

    /// Whether a purchased shipping label can be viewed (and printed, tracked, refunded, etc.).
    var canViewLabel: Bool {
        shippingLabel != nil
    }

    /// View model for the section displayed after a shipping label is purchased.
    @Published private(set) var postPurchase: WooShippingPostPurchaseViewModel?

    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    // TODO: Update this to a property that refers to the package, when selected
    /// Whether there is a package selected for the shipping label.
    /// Temporary property that can be set to `true` to enable features that require a selected package, until package feature is complete.
    let hasPackage: Bool = false

    /// View model for the label shipping service.
    private(set) var shippingService: WooShippingServiceViewModel

    /// Selected shipping rate when creating a shipping label.
    private var selectedRate: WooShippingSelectedRate? {
        shippingService.selectedRate
    }

    /// Address to ship from (store address), formatted for display.
    let originAddress: String

    /// Address to ship to (customer address), formatted for display and split into separate lines to allow additional formatting.
    let destinationAddressLines: [String]

    /// Shipping lines for the order, with formatted amount.
    let shippingLines: [WooShipping_ShippingLineViewModel]

    /// Shipping rates for the purchased label, with formatted amount.
    var shippingRates: [(title: String, amount: String)] {
        if let shippingLabel {
            return [formatShippingRate(name: shippingLabel.serviceName, rate: shippingLabel.rate)]
        } else if let selectedRate {
            let baseRate = selectedRate.rate.rate
            let formattedBaseRate = formatShippingRate(name: Localization.baseRateLabel(for: selectedRate), rate: baseRate)
            let formattedSignatureRate = [
                selectedRate.signatureRate.map { self.formatShippingRate(name: Localization.signatureRequired, rate: $0.rate, basedOn: baseRate) },
                selectedRate.adultSignatureRate.map { self.formatShippingRate(name: Localization.adultSignatureRequired,
                                                                              rate: $0.rate,
                                                                              basedOn: baseRate) }
            ].compacted()
            return [formattedBaseRate] + formattedSignatureRate
        } else {
            return []
        }
    }

    /// Total cost of the shipping label, formatted for display.
    var totalCost: String? {
        guard let amount = shippingLabel?.rate ?? selectedRate?.totalRate else {
            return nil
        }
        return currencyFormatter.formatAmount(Decimal(amount))
    }

    /// Whether to mark the order as complete after the label is purchased.
    @Published var markOrderComplete: Bool = false

    /// If the purchase button should be enabled.
    var canPurchaseLabel: Bool {
        selectedRate != nil && shippingLabel == nil
    }

    /// Closure to execute after the label is successfully purchased.
    let onLabelPurchase: ((_ markOrderComplete: Bool) -> Void)?

    init(order: Order,
         shippingLabel: ShippingLabel? = nil,
         siteAddress: SiteAddress = SiteAddress(),
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingService: WooShippingServiceViewModel = WooShippingServiceViewModel(),
         onLabelPurchase: ((Bool) -> Void)? = nil) {
        self.shippingLabel = shippingLabel
        if let shippingLabel {
            self.postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)
        }
        self.items = WooShippingItemsViewModel(dataSource: DefaultWooShippingItemsDataSource(order: order))
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.onLabelPurchase = onLabelPurchase
        self.originAddress = Self.formatOriginAddress(siteAddress: siteAddress)
        self.destinationAddressLines = (order.shippingAddress?.formattedPostalAddress ?? "").components(separatedBy: .newlines)
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0) })
        self.shippingService = shippingService
    }

    /// Purchases a shipping label with the provided label details and settings.
    func purchaseLabel() {
        guard canPurchaseLabel else {
            return
        }
        // TODO: 13556 - Add action to purchase label remotely
        // TODO: 13556 - If the remote purchase is successful:
            onLabelPurchase?(markOrderComplete)
        if let shippingLabel {
            postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)
        }
    }
}

private extension WooShippingCreateLabelsViewModel {
    /// Provides the formatted label and amount for a shipping rate, based on the provided base rate.
    func formatShippingRate(name: String, rate: Double, basedOn baseRate: Double? = nil) -> (title: String, amount: String) {
        let amount = {
            guard let baseRate else {
                return rate
            }
            return rate - baseRate
        }()
        return (name, currencyFormatter.formatAmount(Decimal(amount)) ?? amount.description)
    }

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

private extension WooShippingCreateLabelsViewModel {
    enum Localization {
        static func baseRateLabel(for selectedRate: WooShippingSelectedRate) -> String {
            if selectedRate.signatureRate == nil && selectedRate.adultSignatureRate == nil {
                return selectedRate.rate.title
            } else {
                return String.localizedStringWithFormat(baseFeeFormat, selectedRate.rate.title)
            }
        }
        private static let baseFeeFormat = NSLocalizedString("wooShipping.createLabels.bottomSheet.baseFee",
                                                             value: "%1$@ (base fee)",
                                                             comment: "Label for row showing the base fee for the selected shipping service " +
                                                             "on the shipping label creation screen. Reads like: 'USPS - Media Mail (base fee)'")
        static let signatureRequired = NSLocalizedString("wooShipping.createLabels.bottomSheet.signatureRequired",
                                                         value: "Signature Required",
                                                         comment: "Label for row showing the additional cost to require a signature " +
                                                         "on the shipping label creation screen")
        static let adultSignatureRequired = NSLocalizedString("wooShipping.createLabels.bottomSheet.adultSignatureRequired",
                                                              value: "Adult Signature Required",
                                                              comment: "Label for row showing the additional cost to require an adult signature " +
                                                              "on the shipping label creation screen")
    }
}
