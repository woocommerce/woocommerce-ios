import Foundation
import enum Yosemite.CardPresentPaymentOnboardingState
@testable import WooCommerce

class MockOnboardingViewContainerConfiguration: CardPresentPaymentsOnboardingViewConfiguration {
    var showSupport: (() -> Void)?
    var showURL: ((URL) -> Void)?
    var state: CardPresentPaymentOnboardingState = .loading
}
