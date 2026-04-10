import UIKit
import Yosemite
import WooFoundation

final class WooShippingServiceCardViewModel: Identifiable, ObservableObject {
    let id: String

    /// Whether this service rate is selected.
    @Published var selected: Bool

    /// The selected signature requirement for this service rate.
    @Published var signatureRequirement: SignatureRequirement = .none

    @Published private(set) var carbonNeutralSelected: Bool

    @Published private(set) var saturdayDeliverySelected: Bool

    @Published private(set) var additionalHandlingSelected: Bool

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

    let carbonNeutralLabel: String?

    let saturdayDeliveryLabel: String?

    let additionalHandlingLabel: String?

    /// Completion callback
    typealias Completion = (_ rateTitle: String,
                            _ signatureRequirement: SignatureRequirement,
                            _ carbonNeutral: Bool,
                            _ saturdayDelivery: Bool,
                            _ additionalHandling: Bool) -> Void
    private let onCompletion: Completion?

    init(id: String = UUID().uuidString,
         selected: Bool = false,
         signatureRequirement: SignatureRequirement = .none,
         carbonNeutralSelected: Bool = false,
         saturdayDeliverySelected: Bool = false,
         additionalHandlingSelected: Bool = false,
         carrierLogo: UIImage?,
         title: String,
         rateLabel: String,
         daysToDeliveryLabel: String?,
         extraInfoLabel: String?,
         hasTracking: Bool,
         insuranceLabel: String?,
         hasFreePickup: Bool,
         signatureRequiredLabel: String?,
         adultSignatureRequiredLabel: String?,
         carbonNeutralLabel: String?,
         saturdayDeliveryLabel: String?,
         additionalHandlingLabel: String?,
         completion: Completion? = nil) {
        self.id = id
        self.selected = selected
        self.signatureRequirement = signatureRequirement
        self.carbonNeutralSelected = carbonNeutralSelected
        self.saturdayDeliverySelected = saturdayDeliverySelected
        self.additionalHandlingSelected = additionalHandlingSelected
        self.carrierLogo = carrierLogo
        self.title = title
        self.rateLabel = rateLabel
        self.daysToDeliveryLabel = daysToDeliveryLabel
        self.extraInfoLabel = extraInfoLabel
        self.trackingLabel = hasTracking ? Localization.tracking : nil
        self.insuranceLabel = insuranceLabel
        self.freePickupLabel = hasFreePickup ? Localization.freePickup : nil
        self.signatureRequiredLabel = signatureRequiredLabel
        self.adultSignatureRequiredLabel = adultSignatureRequiredLabel
        self.carbonNeutralLabel = carbonNeutralLabel
        self.saturdayDeliveryLabel = saturdayDeliveryLabel
        self.additionalHandlingLabel = additionalHandlingLabel
        self.onCompletion = completion
    }

    convenience init(selected: Bool = false,
                     signatureRequired: Bool = false,
                     adultSignatureRequired: Bool = false,
                     carbonNeutralSelected: Bool = false,
                     saturdayDeliverySelected: Bool = false,
                     additionalHandlingSelected: Bool = false,
                     rate: ShippingLabelCarrierRate,
                     signatureRate: ShippingLabelCarrierRate? = nil,
                     adultSignatureRate: ShippingLabelCarrierRate? = nil,
                     carbonNeutralRate: ShippingLabelCarrierRate? = nil,
                     saturdayDeliveryRate: ShippingLabelCarrierRate? = nil,
                     additionalHandlingRate: ShippingLabelCarrierRate? = nil,
                     currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                     completion: Completion? = nil) {

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let signatureRequirement: SignatureRequirement = {
            if signatureRequired {
                return .signatureRequired
            } else if adultSignatureRequired {
                return .adultSignatureRequired
            } else {
                return .none
            }
        }()

        let rateLabel = currencyFormatter.formatAmount(Decimal(rate.rate)) ?? ""

        let daysToDeliveryLabel: String? = {
            guard let deliveryDays = rate.deliveryDays else {
                return nil
            }
            let formatString = rate.deliveryDays == 1 ? Localization.businessDaySingular : Localization.businessDaysPlural
            return String(format: formatString, deliveryDays)
        }()

        let trackingLabel: String? = rate.hasTracking ? Localization.includesTracking : nil
        let insuranceLabel: String? = {
            guard rate.insurance.isNotEmpty else {
                return nil
            }
            if let doubleInsurance = Double(rate.insurance) {
                guard doubleInsurance > 0 else {
                    return nil
                }
                let insuranceFormatted = currencyFormatter.formatAmount(Decimal(doubleInsurance)) ?? ""
                return String(format: Localization.insuranceAmount, insuranceFormatted)
            } else {
                return String(format: Localization.insuranceLiteral, rate.insurance)
            }
        }()
        let freePickupLabel: String? = rate.isPickupFree ? Localization.freePickup.localizedLowercase : nil
        let extras = [trackingLabel, insuranceLabel?.localizedLowercase, freePickupLabel].compactMap { $0 }
        let extraInfoLabel = extras.isNotEmpty ? extras.joined(separator: ", ") : nil

        func formatSurcharge(serviceRate: Double) -> String {
            let amount = Decimal(serviceRate - rate.rate)
            let isNegative = amount < 0
            let formattedAmount = currencyFormatter.formatAmount(amount, isNegative: isNegative) ?? ""
            let prefix = isNegative ? "" : "+"
            return prefix + formattedAmount
        }

        let signatureRequiredLabel: String? = {
            guard let signatureRate else {
                return nil
            }
            let amount = formatSurcharge(serviceRate: signatureRate.rate)
            return String(format: Localization.signatureRequired, amount)
        }()

        let adultSignatureRequiredLabel: String? = {
            guard let adultSignatureRate else {
                return nil
            }
            let amount = formatSurcharge(serviceRate: adultSignatureRate.rate)
            return String(format: Localization.adultSignatureRequired, amount)
        }()

        let carbonNeutralLabel: String? = {
            guard let carbonNeutralRate else {
                return nil
            }
            let amount = formatSurcharge(serviceRate: carbonNeutralRate.rate)
            return String(format: Localization.carbonNeural, amount)
        }()

        let saturdayDeliveryLabel: String? = {
            guard let saturdayDeliveryRate else {
                return nil
            }
            let amount = formatSurcharge(serviceRate: saturdayDeliveryRate.rate)
            return String(format: Localization.saturdayDelivery, amount)
        }()

        let additionalHandlingLabel: String? = {
            guard let additionalHandlingRate else {
                return nil
            }
            let amount = formatSurcharge(serviceRate: additionalHandlingRate.rate)
            return String(format: Localization.additionalHandling, amount)
        }()

        self.init(selected: selected,
                  signatureRequirement: signatureRequirement,
                  carbonNeutralSelected: carbonNeutralSelected,
                  saturdayDeliverySelected: saturdayDeliverySelected,
                  additionalHandlingSelected: additionalHandlingSelected,
                  carrierLogo: WooShippingCarrier(rawValue: rate.carrierID)?.logo,
                  title: rate.title,
                  rateLabel: rateLabel,
                  daysToDeliveryLabel: daysToDeliveryLabel,
                  extraInfoLabel: extraInfoLabel,
                  hasTracking: rate.hasTracking,
                  insuranceLabel: insuranceLabel,
                  hasFreePickup: rate.isPickupFree,
                  signatureRequiredLabel: signatureRequiredLabel,
                  adultSignatureRequiredLabel: adultSignatureRequiredLabel,
                  carbonNeutralLabel: carbonNeutralLabel,
                  saturdayDeliveryLabel: saturdayDeliveryLabel,
                  additionalHandlingLabel: additionalHandlingLabel,
                  completion: completion)
    }

    /// Calls the completion callback with the rate title and signature requirement.
    func selectRate() {
        onCompletion?(title,
                      signatureRequirement,
                      carbonNeutralSelected,
                      saturdayDeliverySelected,
                      additionalHandlingSelected)
    }

    /// Sets `signatureRequirement` when a signature option is tapped.
    func handleTap(on signatureRequirement: SignatureRequirement) {
        if self.signatureRequirement == signatureRequirement {
            self.signatureRequirement = .none
        } else {
            self.signatureRequirement = signatureRequirement
        }
        selectRate()
    }

    func handleTap(on extraRate: ExtraRate) {
        switch extraRate {
        case .carbonNeutral:
            carbonNeutralSelected.toggle()
        case .saturdayDelivery:
            saturdayDeliverySelected.toggle()
        case .additionalHandling:
            additionalHandlingSelected.toggle()
        }
        selectRate()
    }
}

extension WooShippingServiceCardViewModel {
    /// Options for a required signature on delivery for a service rate.
    enum SignatureRequirement {
        case none
        case signatureRequired
        case adultSignatureRequired
    }

    enum ExtraRate {
        case carbonNeutral
        case saturdayDelivery
        case additionalHandling
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
                                                        value: "Insurance (%1$@)",
                                                        comment: "Label when shipping rate includes insurance in Woo Shipping label creation flow. " +
                                                        "Placeholder is a literal. Reads like: 'Insurance (limited)'")
        static let insuranceAmount = NSLocalizedString("wooShipping.createLabels.shippingService.insuranceAmount",
                                                       value: "Insurance (up to %1$@)",
                                                       comment: "Label when shipping rate includes insurance in Woo Shipping label creation flow. " +
                                                       "Placeholder is an amount. Reads like: 'Insurance (up to $100)'")
        static let freePickup = NSLocalizedString("wooShipping.createLabels.shippingService.freePickup",
                                                  value: "Free pickup",
                                                  comment: "Label when shipping rate includes free pickup in Woo Shipping label creation flow.")
        static let signatureRequired = NSLocalizedString("wooShipping.createLabels.shippingService.signatureRequiredLabel",
                                                         value: "Signature Required (%1$@)",
                                                         comment: "Label when shipping rate has option to require a signature in " +
                                                         "Woo Shipping label creation flow. Reads like: 'Signature required (+$3.70)'")
        static let adultSignatureRequired = NSLocalizedString("wooShipping.createLabels.shippingService.adultSignatureRequiredLabel",
                                                              value: "Adult Signature Required (%1$@)",
                                                              comment: "Label when shipping rate has option to require an adult signature in " +
                                                              "Woo Shipping label creation flow. Reads like: 'Adult signature required (+$9.35)'")
        static let carbonNeural = NSLocalizedString(
            "wooShipping.createLabels.shippingService.carbonNeural",
            value: "Carbon Neutral (%1$@)",
            comment: "Label when shipping rate has option for carbon neutral delivery in " +
            "Woo Shipping label creation flow. Reads like: 'Carbon Neutral (+$9.35)'"
        )
        static let saturdayDelivery = NSLocalizedString(
            "wooShipping.createLabels.shippingService.saturdayDelivery",
            value: "Saturday Delivery (%1$@)",
            comment: "Label when shipping rate has option for Saturday delivery in " +
            "Woo Shipping label creation flow. Reads like: 'Saturday Delivery (+$9.35)'"
        )
        static let additionalHandling = NSLocalizedString(
            "wooShipping.createLabels.shippingService.additionalHandling",
            value: "Additional Handling (%1$@)",
            comment: "Label when shipping rate has option for additional handling in " +
            "Woo Shipping label creation flow. Reads like: 'Additional Handling (+$9.35)'"
        )
    }
}
