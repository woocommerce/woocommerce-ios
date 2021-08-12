import Combine
import Yosemite

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState
    @Published var showLoadingScreen: Bool = false

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
        // If onboarding has been completed once, it is unlikely that the state will change
        // so we will skip showing the loading screen every time
        showLoadingScreen = state != .completed

        useCase.synchronizeRequiredData { [weak self] in
            guard let self = self else {
                return
            }
            self.state = self.useCase.checkOnboardingState()
            self.showLoadingScreen = false
        }
    }
}
