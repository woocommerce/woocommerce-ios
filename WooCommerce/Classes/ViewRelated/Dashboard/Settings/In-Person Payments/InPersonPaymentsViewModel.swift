import Combine
import Yosemite

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState

    /// Initializes the view model for a specific site
    ///
    init(siteID: Int64) {
        let useCase = CardPresentPaymentsOnboardingUseCase(
            siteID: siteID,
            storageManager: ServiceLocator.storageManager,
            dispatch: { action in ServiceLocator.stores.dispatch(action) }
        )
        state = useCase.checkOnboardingState()
        useCase.synchronizeRequiredData { [weak self] in
            guard let self = self else {
                return
            }
            self.state = useCase.checkOnboardingState()
        }
    }

    /// Initializes the view model with a fixed state that never changes.
    /// This is useful for SwiftUI previews or testing, but shouldn't be used in production
    ///
    init(fixedState: CardPresentPaymentOnboardingState) {
        state = fixedState
    }
}
