import Combine
import Yosemite

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState

    private let useCase = CardPresentPaymentsOnboardingUseCase()

    /// Initializes the view model for a specific site
    ///
    init() {
        state = useCase.checkOnboardingState()
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
        useCase.synchronizeRequiredData { [weak self] in
            guard let self = self else {
                return
            }
            self.state = self.useCase.checkOnboardingState()
        }
    }
}
