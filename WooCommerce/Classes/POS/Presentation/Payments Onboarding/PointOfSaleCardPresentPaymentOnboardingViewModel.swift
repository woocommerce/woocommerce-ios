import Foundation
import SwiftUI
import enum Yosemite.CardPresentPaymentOnboardingState

protocol CardPresentPaymentsOnboardingViewConfiguration: ObservableObject {
    var showSupport: (() -> Void)? { get set }
    var showURL: ((URL) -> Void)? { get set }
    var state: CardPresentPaymentOnboardingState { get }
}

final class CardPresentPaymentOnboardingViewFactory: ObservableObject, Equatable, Identifiable {
    @Published var configuration: any CardPresentPaymentsOnboardingViewConfiguration
    @Published var view: any View

    init(configuration: any CardPresentPaymentsOnboardingViewConfiguration, view: any View = EmptyView()) {
        self.configuration = configuration
        self.view = view
    }

    static func == (lhs: CardPresentPaymentOnboardingViewFactory, rhs: CardPresentPaymentOnboardingViewFactory) -> Bool {
        lhs.configuration.state == rhs.configuration.state
    }
}

final class PointOfSaleCardPresentPaymentOnboardingViewModel: ObservableObject {
    @Published var onboardingURL: URL?
    @Published var onboardingViewFactory: CardPresentPaymentOnboardingViewFactory

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
