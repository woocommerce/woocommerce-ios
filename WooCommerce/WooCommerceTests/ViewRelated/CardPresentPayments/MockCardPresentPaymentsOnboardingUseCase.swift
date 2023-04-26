import Combine
@testable import WooCommerce
@testable import Yosemite

/// Simple mock for `CardPresentPaymentsOnboardingUseCaseProtocol`
///
final class MockCardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol {
    // MARK: Protocol properties
    @Published var state: CardPresentPaymentOnboardingState
    var statePublisher: Published<CardPresentPaymentOnboardingState>.Publisher {
        $state
    }

    var refreshWasCalled = false

    // MARK: Protocol Methods
    func refresh() {
        refreshWasCalled = true
    }

    func updateState() {
        // No op
    }

    var skipPendingRequirementsWasCalled = false
    func skipPendingRequirements() {
        skipPendingRequirementsWasCalled = true
    }

    var selectPluginWasCalled = false
    var spySelectedPlugin: CardPresentPaymentsPlugin? = nil
    func selectPlugin(_ selectedPlugin: CardPresentPaymentsPlugin) {
        selectPluginWasCalled = true
        spySelectedPlugin = selectedPlugin
    }

    var clearPluginSelectionWasCalled = false
    func clearPluginSelection() {
        clearPluginSelectionWasCalled = true
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
