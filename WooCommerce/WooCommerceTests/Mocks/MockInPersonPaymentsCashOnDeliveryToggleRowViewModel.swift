import Foundation
@testable import WooCommerce
import Yosemite

final class MockInPersonPaymentsCashOnDeliveryToggleRowViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModelProtocol {
var spyDidCallRefreshState = false
    func refreshState() {
        spyDidCallRefreshState = true
    }

    var selectedPlugin: CardPresentPaymentsPlugin? = nil
}
