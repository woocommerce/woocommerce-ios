import Foundation
import SwiftUI
import enum Yosemite.CardPresentPaymentOnboardingState

public protocol CardPresentPaymentsOnboardingViewConfiguration: ObservableObject {
    var showSupport: (() -> Void)? { get set }
    var showURL: ((URL) -> Void)? { get set }
    var state: CardPresentPaymentOnboardingState { get }
}

public class CardPresentPaymentOnboardingViewContainer: ObservableObject, Equatable, Identifiable {
    @Published var configuration: any CardPresentPaymentsOnboardingViewConfiguration
    @Published var view: any View

    public init(configuration: any CardPresentPaymentsOnboardingViewConfiguration, view: any View = EmptyView()) {
        self.configuration = configuration
        self.view = view
    }

    public static func == (lhs: CardPresentPaymentOnboardingViewContainer, rhs: CardPresentPaymentOnboardingViewContainer) -> Bool {
        lhs.configuration.state == rhs.configuration.state
    }
}

final class PointOfSaleCardPresentPaymentOnboardingViewModel: ObservableObject {
    @Published var onboardingURL: URL?
    @Published var onboardingViewContainer: CardPresentPaymentOnboardingViewContainer

    private let onDismissTap: (() -> Void)?

    init(onboardingViewContainer: CardPresentPaymentOnboardingViewContainer,
         onDismissTap: (() -> Void)?) {
        self.onboardingViewContainer = onboardingViewContainer
        self.onDismissTap = onDismissTap
        self.onboardingViewContainer.configuration.showURL = { [weak self] url in
            self?.onboardingURL = url
        }
    }

    /// Called when the user taps to dismiss the onboarding UI.
    func cancelOnboarding() {
        onDismissTap?()
    }
}
