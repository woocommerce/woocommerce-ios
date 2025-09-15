import Foundation
import Yosemite

extension CardPresentPaymentsPlugin {
    var manageCardReaderLearnMoreURL: URL {
        switch self {
        case .wcPay:
            return WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL()
        case .stripe:
            return WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()
        case .paypal:
                    fatalError("Not implemented yet")
        }
    }

    var setUpTapToPayLearnMoreURL: URL {
        switch self {
        case .wcPay:
            return WooConstants.URLs.inPersonPaymentsLearnMoreWCPayTapToPay.asURL()
        case .stripe:
            return WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()
        case .paypal:
                    fatalError("Not implemented yet")
        }
    }
}
