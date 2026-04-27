import Codegen

/// Represents a selected shipping rate with the Woo Shipping extension.
public struct WooShippingSelectedRate: Equatable, GeneratedFakeable {

    /// Basic rate for the selected carrier without additional service.
    public let rate: ShippingLabelCarrierRate

    /// Rate for shipping with signature, if selected.
    public let signatureRate: ShippingLabelCarrierRate?

    /// Rate for shipping with adult signature, if selected.
    public let adultSignatureRate: ShippingLabelCarrierRate?

    /// Rate for shipping with carbon neutral, if selected.
    public let carbonNeutralRate: ShippingLabelCarrierRate?

    /// Rate for shipping with Saturday delivery, if selected.
    public let saturdayDeliveryRate: ShippingLabelCarrierRate?

    /// Rate for shipping with additional handling, if selected.
    public let additionalHandlingRate: ShippingLabelCarrierRate?

    public init(rate: ShippingLabelCarrierRate,
                signatureRate: ShippingLabelCarrierRate? = nil,
                adultSignatureRate: ShippingLabelCarrierRate? = nil,
                carbonNeutralRate: ShippingLabelCarrierRate? = nil,
                saturdayDeliveryRate: ShippingLabelCarrierRate? = nil,
                additionalHandlingRate: ShippingLabelCarrierRate? = nil) {
        self.rate = rate
        self.signatureRate = signatureRate
        self.adultSignatureRate = adultSignatureRate
        self.carbonNeutralRate = carbonNeutralRate
        self.saturdayDeliveryRate = saturdayDeliveryRate
        self.additionalHandlingRate = additionalHandlingRate
    }
}

public extension WooShippingSelectedRate {
    var purchaseRate: ShippingLabelCarrierRate {
        if let signatureRate {
            return signatureRate
        } else if let adultSignatureRate {
            return adultSignatureRate
        }
        return rate
    }

    var totalRate: Double {
        let totalRateExcludingExtraServices: Double = {
            if let signatureRate {
                return signatureRate.rate
            } else if let adultSignatureRate {
                return adultSignatureRate.rate
            }
            return rate.rate
        }()

        let allCharges = [totalRateExcludingExtraServices,
                          surchargeForCarbonNeutralRate,
                          surchargeForSaturdayDeliveryRate,
                          surchargeForAdditionalHandlingRate]

        return allCharges.reduce(0, +)
    }
}

extension WooShippingSelectedRate {
    var surchargeForSignatureRequirement: Double {
        guard let signatureRate else {
            return 0
        }
        return signatureRate.rate - rate.rate
    }

    var surchargeForAdultSignatureRequirement: Double {
        guard let adultSignatureRate else {
            return 0
        }
        return adultSignatureRate.rate - rate.rate
    }

    var surchargeForCarbonNeutralRate: Double {
        guard let carbonNeutralRate else {
            return 0
        }
        return carbonNeutralRate.rate - rate.rate
    }

    var surchargeForSaturdayDeliveryRate: Double {
        guard let saturdayDeliveryRate else {
            return 0
        }
        return saturdayDeliveryRate.rate - rate.rate
    }

    var surchargeForAdditionalHandlingRate: Double {
        guard let additionalHandlingRate else {
            return 0
        }
        return additionalHandlingRate.rate - rate.rate
    }
}
