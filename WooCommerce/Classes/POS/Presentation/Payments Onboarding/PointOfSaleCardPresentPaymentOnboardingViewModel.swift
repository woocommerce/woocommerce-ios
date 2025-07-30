import Foundation
import SwiftUI
import enum Yosemite.CardPresentPaymentOnboardingState

protocol CardPresentPaymentsOnboardingViewConfiguration: AnyObject {
    var showSupport: (() -> Void)? { get set }
    var showURL: ((URL) -> Void)? { get set }
    var state: CardPresentPaymentOnboardingState { get }
}

final class CardPresentPaymentOnboardingViewFactory: Equatable, Identifiable {
    var configuration: CardPresentPaymentsOnboardingViewConfiguration
    let createView: () -> any View

    init(configuration: CardPresentPaymentsOnboardingViewConfiguration, createView: @escaping () -> any View = { EmptyView() }) {
        self.configuration = configuration
        self.createView = createView
    }

    static func == (lhs: CardPresentPaymentOnboardingViewFactory, rhs: CardPresentPaymentOnboardingViewFactory) -> Bool {
        lhs.configuration.state == rhs.configuration.state
    }
}

final class PointOfSaleCardPresentPaymentOnboardingViewModel: ObservableObject {
    @Published var onboardingURL: URL?
    let onboardingViewFactory: CardPresentPaymentOnboardingViewFactory

    private let onDismissTap: (() -> Void)?

    init(onboardingViewFactory: CardPresentPaymentOnboardingViewFactory,
         onDismissTap: (() -> Void)?) {
        self.onboardingViewFactory = onboardingViewFactory
        self.onDismissTap = onDismissTap
        self.onboardingViewFactory.configuration.showURL = { [weak self] url in
            self?.onboardingURL = url
        }
    }

    /// Called when the user taps to dismiss the onboarding UI.
    func cancelOnboarding() {
        onDismissTap?()
    }
}
