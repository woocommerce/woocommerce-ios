import Yosemite

/// Represents a selected shipping rate with the Woo Shipping extension.
struct WooShippingSelectedRate {
    /// Basic rate for the selected carrier without additional service.
    let rate: ShippingLabelCarrierRate

    /// Rate for shipping with signature, if selected.
    let signatureRate: ShippingLabelCarrierRate?

    /// Rate for shipping with adult signature, if selected.
    let adultSignatureRate: ShippingLabelCarrierRate?

    /// Rate for shipping with carbon neutral, if selected.
    let carbonNeutralRate: ShippingLabelCarrierRate?

    /// Rate for shipping with Saturday delivery, if selected.
    let saturdayDeliveryRate: ShippingLabelCarrierRate?

    /// Rate for shipping with additional handling, if selected.
    let additionalHandlingRate: ShippingLabelCarrierRate?
}

extension WooShippingSelectedRate {
    var purchaseRate: ShippingLabelCarrierRate {
        if let signatureRate = signatureRate {
            return signatureRate
        } else if let adultSignatureRate = adultSignatureRate {
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

private extension WooShippingSelectedRate {
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
