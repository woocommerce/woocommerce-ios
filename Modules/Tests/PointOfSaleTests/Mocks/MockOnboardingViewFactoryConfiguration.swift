import Foundation
import enum Yosemite.CardPresentPaymentOnboardingState
@testable import PointOfSale

class MockOnboardingViewContainerConfiguration: CardPresentPaymentsOnboardingViewConfiguration {
    var showSupport: (() -> Void)?
    var showURL: ((URL) -> Void)?
    var state: CardPresentPaymentOnboardingState = .loading
}
