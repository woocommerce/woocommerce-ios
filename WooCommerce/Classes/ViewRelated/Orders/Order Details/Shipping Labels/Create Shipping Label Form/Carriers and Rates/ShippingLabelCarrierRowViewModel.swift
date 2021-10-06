import SwiftUI
import Yosemite

struct ShippingLabelCarrierRowViewModel: Identifiable {
    internal let id = UUID()
    let selected: Bool
    let signatureSelected: Bool
    let adultSignatureSelected: Bool
    private let rate: ShippingLabelCarrierRate
    private let signatureRate: ShippingLabelCarrierRate?
    private let adultSignatureRate: ShippingLabelCarrierRate?

    let title: String
    let subtitle: String?
    let price: String
    let carrierLogo: UIImage?

    let extraInfo: String

    let displaySignatureRequired: Bool
    let displayAdultSignatureRequired: Bool
    let signatureRequiredText: String
    let adultSignatureRequiredText: String

    /// Completion callback
    ///
    typealias Completion = (_ selected: ShippingLabelCarrierRate,
                            _ signatureRateSelected: ShippingLabelCarrierRate?,
                            _ adultSignatureRateSelected: ShippingLabelCarrierRate?) -> Void
    private let onCompletion: Completion

    init(selected: Bool = false,
         signatureSelected: Bool = false,
         adultSignatureSelected: Bool = false,
         rate: ShippingLabelCarrierRate,
         signatureRate: ShippingLabelCarrierRate? = nil,
         adultSignatureRate: ShippingLabelCarrierRate? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         completion: @escaping Completion) {
        self.selected = selected
        self.signatureSelected = signatureSelected
        self.adultSignatureSelected = adultSignatureSelected
        self.rate = rate
        self.signatureRate = signatureRate
        self.adultSignatureRate = adultSignatureRate
        onCompletion = completion

        title = rate.title
        let formatString = rate.deliveryDays == 1 ? Localization.businessDaySingular : Localization.businessDaysPlural
        if let deliveryDays = rate.deliveryDays {
            subtitle = String(format: formatString, deliveryDays)
        }
        else {
            subtitle = nil
        }

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        price = {
            if signatureSelected, let signatureRate = signatureRate {
                    return currencyFormatter.formatAmount(Decimal(signatureRate.retailRate)) ?? ""
                }
                if adultSignatureSelected, let adultSignatureRate = adultSignatureRate {
                    return currencyFormatter.formatAmount(Decimal(adultSignatureRate.retailRate)) ?? ""
                }
            return currencyFormatter.formatAmount(Decimal(rate.retailRate)) ?? ""
        }()

        carrierLogo = CarrierLogo(rawValue: rate.carrierID)?.image()

        var extras: [String] = []
        if rate.hasTracking {
            extras.append(String(format: Localization.tracking, rate.carrierID.uppercased()))
        }

        if let doubleInsurance = Double(rate.insurance) {
            if doubleInsurance > 0 {
                let insuranceFormatted = currencyFormatter.formatAmount(Decimal(doubleInsurance)) ?? ""
                extras.append(String(format: Localization.insuranceAmount, insuranceFormatted))
            }
        } else if rate.insurance.isNotEmpty {
            extras.append(String(format: Localization.insuranceLiteral, rate.insurance))
        }

        if rate.isPickupFree {
            extras.append(Localization.freePickup)
        }

        extraInfo = extras.joined(separator: ", ")

        displaySignatureRequired = signatureRate != nil
        displayAdultSignatureRequired = adultSignatureRate != nil

        if displaySignatureRequired, let signatureRate = signatureRate {
            let amount = currencyFormatter.formatAmount(Decimal(signatureRate.retailRate - rate.retailRate)) ?? ""
              signatureRequiredText = String(format: Localization.signatureRequired, amount)
        } else {
            signatureRequiredText = ""
        }

        if displayAdultSignatureRequired, let adultSignatureRate = adultSignatureRate {
            let amount = currencyFormatter.formatAmount(Decimal(adultSignatureRate.retailRate - rate.retailRate)) ?? ""
            adultSignatureRequiredText = String(format: Localization.adultSignatureRequired, amount)
        }
        else {
            adultSignatureRequiredText = ""
        }
    }

    func handleSelection() {
        onCompletion(rate, nil, nil)
    }

    func handleSignatureSelection() {
        guard !signatureSelected else {
            onCompletion(rate, nil, nil)
            return
        }
        onCompletion(rate, signatureRate, nil)
    }

    func handleAdultSignatureSelection() {
        guard !adultSignatureSelected else {
            onCompletion(rate, nil, nil)
            return
        }
        onCompletion(rate, nil, adultSignatureRate)
    }
}

extension ShippingLabelCarrierRowViewModel: Equatable {
    static func == (lhs: ShippingLabelCarrierRowViewModel, rhs: ShippingLabelCarrierRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

private extension ShippingLabelCarrierRowViewModel {
    enum Localization {
        static let businessDaySingular =
            NSLocalizedString("%1$d business day", comment: "Singular format of number of business day in Shipping Labels > Carrier and Rates")
        static let businessDaysPlural =
            NSLocalizedString("%1$d business days", comment: "Plural format of number of business days in Shipping Labels > Carrier and Rates")
        static let tracking = NSLocalizedString("Includes %1$@ tracking",
                                                comment: "Includes tracking of a specific carrier in Shipping Labels > Carrier and Rates")
        static let insuranceLiteral = NSLocalizedString("Insurance (%1$@)",
                                                        comment: "Includes insurance of a specific carrier in Shipping Labels > Carrier and Rates. " +
                                                            "Placeholder is a literal, e.g \"limited\"")
        static let insuranceAmount = NSLocalizedString("Insurance (up to %1$@)",
                                                       comment: "Includes insurance of a specific carrier in Shipping Labels > Carrier and Rates. " +
                                                            "Place holder is an amount.")
        static let freePickup = NSLocalizedString("Eligible for free pickup",
                                                  comment: "Carrier eligible for free pickup in Shipping Labels > Carrier and Rates")
        static let signatureRequired = NSLocalizedString("Signature required (+%1$@)",
                                                         comment: "Signature required in Shipping Labels > Carrier and Rates")
        static let adultSignatureRequired = NSLocalizedString("Adult signature required (+%1$@)",
                                                              comment: "Adult signature required in Shipping Labels > Carrier and Rates")
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
