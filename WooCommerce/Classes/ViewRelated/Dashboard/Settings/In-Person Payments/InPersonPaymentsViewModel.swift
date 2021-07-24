import Yosemite
import Combine

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState

    init(initialState: CardPresentPaymentOnboardingState) {
        state = initialState
    }
}
