import Yosemite

struct ShippingLabelCarrierRowViewModel: Identifiable {
    internal let id = UUID()
    let selected: Bool
    let signatureSelected: Bool
    let adultSignatureSelected: Bool
    let rate: ShippingLabelCarrierRate
    let signatureRate: ShippingLabelCarrierRate?
    let adultSignatureRate: ShippingLabelCarrierRate?

    let title: String
    let subtitle: String
    let price: String
    let carrierLogo: UIImage?

    let extraInfo: String

    init(selected: Bool = false,
         signatureSelected: Bool = false,
         adultSignatureSelected: Bool = false,
         rate: ShippingLabelCarrierRate,
         signatureRate: ShippingLabelCarrierRate? = nil,
         adultSignatureRate: ShippingLabelCarrierRate? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.selected = selected
        self.signatureSelected = signatureSelected
        self.adultSignatureSelected = adultSignatureSelected
        self.rate = rate
        self.signatureRate = signatureRate
        self.adultSignatureRate = adultSignatureRate

        title = rate.title
        let formatString = rate.deliveryDays == 1 ? Localization.businessDaySingular : Localization.businessDaysPlural
        subtitle = String(format: formatString, rate.deliveryDays)

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        price = currencyFormatter.formatAmount(Decimal(rate.retailRate)) ?? ""

        carrierLogo = CarrierLogo(rawValue: rate.carrierID)?.image()

        var extras: [String] = []
        if rate.hasTracking {
            extras.append(String(format: Localization.tracking, rate.carrierID.uppercased()))
        }
        if rate.insurance > 0 {
            let insuranceFormatted = currencyFormatter.formatAmount(Decimal(rate.insurance)) ?? ""
            extras.append(String(format: Localization.insurance, insuranceFormatted))
        }
        if rate.isPickupFree {
            extras.append(Localization.freePickup)
        }

        extraInfo = extras.joined(separator: ", ")
    }

    enum Localization {
        static let businessDaySingular =
            NSLocalizedString("%1$d business day", comment: "Singular format of number of business day in Shipping Labels > Carrier and Rates")
        static let businessDaysPlural =
            NSLocalizedString("%1$d business days", comment: "Plural format of number of business days in Shipping Labels > Carrier and Rates")
        static let tracking = NSLocalizedString("Includes %1$@ tracking",
                                                comment: "Includes tracking of a specific carrier in Shipping Labels > Carrier and Rates")
        static let insurance = NSLocalizedString("Insurance (up to %1$@)",
                                                 comment: "Includes insurance of a specific carrier in Shipping Labels > Carrier and Rates")
        static let freePickup = NSLocalizedString("Eligible for free pickup",
                                                  comment: "Carrier eligible for free pickup in Shipping Labels > Carrier and Rates")
    }

    enum CarrierLogo: String {
        case ups
        case usps
        case dhlExpress = "dhlexpress"
        case dhlEcommerce = "dhlecommerce"
        case dhlEcommerceAsia = "dhlecommerceasia"

        func image() -> UIImage? {
            switch self {
            case .ups:
                return UIImage(named: "shipping-label-ups-logo")
            case .usps:
                return UIImage(named: "shipping-label-usps-logo")
            case .dhlExpress, .dhlEcommerce, .dhlEcommerceAsia:
                return UIImage(named: "shipping-label-fedex-logo")
            }
        }
    }
}
