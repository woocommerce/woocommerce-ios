import Combine
import Yosemite

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState

    private let useCase = CardPresentPaymentsOnboardingUseCase()

    /// Initializes the view model for a specific site
    ///
    init() {
        state = useCase.state
        useCase.$state
            // Debounce values to prevent the loading screen flashing when there is no connection
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: trackState(_:))
            .assign(to: &$state)
        refresh()
    }

    /// Initializes the view model with a fixed state that never changes.
    /// This is useful for SwiftUI previews or testing, but shouldn't be used in production
    ///
    init(fixedState: CardPresentPaymentOnboardingState) {
        state = fixedState
    }

    /// Synchronizes the required data from the server and recalculates the state
    ///
    func refresh() {
        useCase.refresh()
    }

    func updateGateway(useStripe: Bool) {
        useCase.refresh()
    }
}

private func trackState(_ state: CardPresentPaymentOnboardingState) {
    guard let reason = state.reasonForAnalytics else {
        return
    }
    let properties = [
        "reason": reason
    ]
    ServiceLocator.analytics.track(.cardPresentOnboardingNotCompleted, withProperties: properties)
}
