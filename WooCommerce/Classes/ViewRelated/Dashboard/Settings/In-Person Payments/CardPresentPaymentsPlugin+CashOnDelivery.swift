import Foundation
import Yosemite

extension CardPresentPaymentsPlugin {
    var cashOnDeliveryLearnMoreURL: URL {
        switch self {
        case .wcPay:
            return WooConstants.URLs.wcPayCashOnDeliveryLearnMore.asURL()
        case .stripe:
            return WooConstants.URLs.stripeCashOnDeliveryLearnMore.asURL()
        }
    }
}
