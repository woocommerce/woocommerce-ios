import Foundation
import enum Yosemite.CardPresentPaymentOnboardingState
@testable import WooCommerce

class MockOnboardingViewFactoryConfiguration: CardPresentPaymentsOnboardingViewConfiguration {
    var showSupport: (() -> Void)?
    var showURL: ((URL) -> Void)?
    var state: CardPresentPaymentOnboardingState = .loading
}
