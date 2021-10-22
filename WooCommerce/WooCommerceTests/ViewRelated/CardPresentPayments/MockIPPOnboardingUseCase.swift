import Combine
@testable import WooCommerce
@testable import Yosemite

/// Simple mock for `IPPOnboardingUseCaseProtocol`
///
final class MockIPPOnboardingUseCase: IPPOnboardingUseCaseProtocol {
    // MARK: Protocol properties
    @Published var state: CardPresentPaymentOnboardingState
    var statePublisher: Published<CardPresentPaymentOnboardingState>.Publisher {
        $state
    }

    // MARK: Protocol Methods
    func refresh() {
        // No op
    }

    func updateState() {
        // No op
    }

    // MARK: Convenience Initializer
    init(initial: CardPresentPaymentOnboardingState, publisher: AnyPublisher<CardPresentPaymentOnboardingState, Never>? = nil) {
        self.state = initial

        /// Assign the publisher if provided
        ///
        if let publisher = publisher {
            publisher.assign(to: &$state)
        }
    }
}
