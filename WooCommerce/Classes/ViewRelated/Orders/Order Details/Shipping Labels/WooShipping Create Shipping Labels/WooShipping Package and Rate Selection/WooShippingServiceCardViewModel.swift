import Yosemite
import WooFoundation

final class WooShippingServiceCardViewModel: Identifiable, ObservableObject {
    let id: String

    /// Whether this service rate is selected.
    @Published var selected: Bool

    /// The selected signature requirement for this service rate.
    @Published var signatureRequirement: SignatureRequirement = .none

    /// Carrier logo for the service rate.
    let carrierLogo: UIImage?

    /// Title for the service rate.
    let title: String

    /// Rate (price) label for the service rate.
    let rateLabel: String

    /// Label showing the number of days to delivery for the service rate.
    let daysToDeliveryLabel: String?

    /// Additional information about the service rate.
    let extraInfoLabel: String?

    /// Label if the service rate has tracking.
    let trackingLabel: String?

    /// Label if the service rate has insurance.
    let insuranceLabel: String?

    /// Label if the service rate has free pickup.
    let freePickupLabel: String?

    /// Label if there is an option to require a signature.
    let signatureRequiredLabel: String?

    /// Label if there is an option to require an adult signature.
    let adultSignatureRequiredLabel: String?

    init(selected: Bool = false,
         signatureRequirement: SignatureRequirement = .none,
         carrierLogo: UIImage?,
         title: String,
         rateLabel: String,
         daysToDeliveryLabel: String?,
         extraInfoLabel: String?,
         trackingLabel: String?,
         insuranceLabel: String?,
         freePickupLabel: String?,
         signatureRequiredLabel: String?,
         adultSignatureRequiredLabel: String?) {
        self.id = UUID().uuidString
        self.selected = selected
        self.signatureRequirement = signatureRequirement
        self.carrierLogo = carrierLogo
        self.title = title
        self.rateLabel = rateLabel
        self.daysToDeliveryLabel = daysToDeliveryLabel
        self.extraInfoLabel = extraInfoLabel
        self.trackingLabel = trackingLabel
        self.insuranceLabel = insuranceLabel
        self.freePickupLabel = freePickupLabel
        self.signatureRequiredLabel = signatureRequiredLabel
        self.adultSignatureRequiredLabel = adultSignatureRequiredLabel
    }

    init(selected: Bool = false,
         signatureRequirement: SignatureRequirement = .none,
         rate: ShippingLabelCarrierRate,
         signatureRate: ShippingLabelCarrierRate? = nil,
         adultSignatureRate: ShippingLabelCarrierRate? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        id = rate.rateID
        self.selected = selected
        self.signatureRequirement = signatureRequirement

        title = rate.title
        let formatString = rate.deliveryDays == 1 ? Localization.businessDaySingular : Localization.businessDaysPlural
        if let deliveryDays = rate.deliveryDays {
            daysToDeliveryLabel = String(format: formatString, deliveryDays)
        }
        else {
            daysToDeliveryLabel = nil
        }

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        rateLabel = {
            switch (signatureRequirement, signatureRate, adultSignatureRate) {
            case (.signatureRequired, .some(let signatureRate), _):
                currencyFormatter.formatAmount(Decimal(signatureRate.rate)) ?? ""
            case (.adultSignatureRequired, _, .some(let adultSignatureRate)):
                currencyFormatter.formatAmount(Decimal(adultSignatureRate.rate)) ?? ""
            default:
                currencyFormatter.formatAmount(Decimal(rate.rate)) ?? ""
            }
        }()

        carrierLogo = CarrierLogo(rawValue: rate.carrierID)?.image()

        var extras: [String] = []
        if rate.hasTracking {
            trackingLabel = Localization.tracking
            extras.append(Localization.includesTracking)
        } else {
            trackingLabel = nil
        }

        if let doubleInsurance = Double(rate.insurance), doubleInsurance > 0 {
            let insuranceFormatted = currencyFormatter.formatAmount(Decimal(doubleInsurance)) ?? ""
            let insuranceString = String(format: Localization.insuranceAmount, insuranceFormatted)
            insuranceLabel = insuranceString
            extras.append(insuranceString.localizedLowercase)
        } else if rate.insurance.isNotEmpty {
            let insuranceString = String(format: Localization.insuranceLiteral, rate.insurance)
            insuranceLabel = insuranceString
            extras.append(insuranceString.localizedLowercase)
        } else {
            insuranceLabel = nil
        }

        if rate.isPickupFree {
            freePickupLabel = Localization.freePickup
            extras.append(Localization.freePickup.localizedLowercase)
        } else {
            freePickupLabel = nil
        }

        extraInfoLabel = extras.isNotEmpty ? extras.joined(separator: ", ") : nil

        if let signatureRate {
            let amount = currencyFormatter.formatAmount(Decimal(signatureRate.rate - rate.rate)) ?? ""
            signatureRequiredLabel = String(format: Localization.signatureRequired, amount)
        } else {
            signatureRequiredLabel = nil
        }

        if let adultSignatureRate {
            let amount = currencyFormatter.formatAmount(Decimal(adultSignatureRate.rate - rate.rate)) ?? ""
            adultSignatureRequiredLabel = String(format: Localization.adultSignatureRequired, amount)
        } else {
            adultSignatureRequiredLabel = nil
        }
    }

    func handleTap(on signatureRequirement: SignatureRequirement) {
        if self.signatureRequirement == signatureRequirement {
            self.signatureRequirement = .none
        } else {
            self.signatureRequirement = signatureRequirement
        }
    }
}

extension WooShippingServiceCardViewModel {
    /// Options for a required signature on delivery for a service rate.
    enum SignatureRequirement {
        case none
        case signatureRequired
        case adultSignatureRequired
    }
}

private extension WooShippingServiceCardViewModel {
    enum Localization {
        static let businessDaySingular = NSLocalizedString("wooShipping.createLabels.shippingService.deliveryDaySingular",
                                                           value: "%1$d business day",
                                                           comment: "Singular format of number of business days in Woo Shipping label creation flow. " +
                                                           "Reads like: '1 business day'")
        static let businessDaysPlural = NSLocalizedString("wooShipping.createLabels.shippingService.deliveryDaysPlural",
                                                          value: "%1$d business days",
                                                          comment: "Plural format of number of business days in Woo Shipping label creation flow. " +
                                                          "Reads like: '3 business days'")
        static let includesTracking = NSLocalizedString("wooShipping.createLabels.shippingService.includesTracking",
                                                        value: "Includes tracking",
                                                        comment: "Label when shipping rate includes tracking in Woo Shipping label creation flow.")
        static let tracking = NSLocalizedString("wooShipping.createLabels.shippingService.tracking",
                                                value: "Tracking",
                                                comment: "Label when shipping rate includes tracking in Woo Shipping label creation flow.")
        static let insuranceLiteral = NSLocalizedString("wooShipping.createLabels.shippingService.insuranceLiteral",
                                                        value: "insurance (%1$@)",
                                                        comment: "Label when shipping rate includes insurance in Woo Shipping label creation flow. " +
                                                        "Placeholder is a literal. Reads like: 'Insurance (limited)'")
        static let insuranceAmount = NSLocalizedString("wooShipping.createLabels.shippingService.insuranceAmount",
                                                       value: "insurance (up to %1$@)",
                                                       comment: "Label when shipping rate includes insurance in Woo Shipping label creation flow. " +
                                                       "Placeholder is an amount. Reads like: 'Insurance (up to $100)'")
        static let freePickup = NSLocalizedString("wooShipping.createLabels.shippingService.freePickup",
                                                  value: "free pickup",
                                                  comment: "Carrier eligible for free pickup in Shipping Labels > Carrier and Rates")
        static let signatureRequired = NSLocalizedString("wooShipping.createLabels.shippingService.signatureRequired",
                                                         value: "Signature required (+%1$@)",
                                                         comment: "Label when shipping rate has option to require a signature in " +
                                                         "Woo Shipping label creation flow. Reads like: 'Signature required (+$3.70)'")
        static let adultSignatureRequired = NSLocalizedString("wooShipping.createLabels.shippingService.adultSignatureRequired",
                                                              value: "Adult signature required (+%1$@)",
                                                              comment: "Label when shipping rate has option to require an adult signature in " +
                                                              "Woo Shipping label creation flow. Reads like: 'Adult signature required (+$9.35)'")
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
                return UIImage(named: "shipping-label-dhl-logo")
            }
        }
    }
}
