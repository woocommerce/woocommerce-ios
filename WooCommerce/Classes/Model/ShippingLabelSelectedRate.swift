import Foundation
import Yosemite
import Codegen

struct ShippingLabelSelectedRate: GeneratedCopiable {

    /// The ID of the package related to the selected rate.
    let packageID: String

    /// Basic rate for the selected carrier without additional service.
    let rate: ShippingLabelCarrierRate

    /// Rate for signature if any.
    let signatureRate: ShippingLabelCarrierRate?

    /// Rate for adult signature if any.
    let adultSignatureRate: ShippingLabelCarrierRate?
}

extension ShippingLabelSelectedRate {
    var retailRate: Double {
        if let signatureRate = signatureRate {
            return signatureRate.retailRate
        } else if let adultSignatureRate = adultSignatureRate {
            return adultSignatureRate.retailRate
        }
        return rate.retailRate
    }

    var discount: Double {
        if let signatureRate = signatureRate {
            return signatureRate.rate - signatureRate.retailRate
        } else if let adultSignatureRate = adultSignatureRate {
            return adultSignatureRate.rate - adultSignatureRate.retailRate
        }
        return rate.rate - rate.retailRate
    }

    var totalRate: Double {
        if let signatureRate = signatureRate {
            return signatureRate.rate
        } else if let adultSignatureRate = adultSignatureRate {
            return adultSignatureRate.rate
        }
        return rate.rate
    }
}
