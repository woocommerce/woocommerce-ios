import Foundation
import Combine
import Yosemite

final class CardPaymentReadinessUseCase {
    /// Represents the system's readiness to accept a card payment
    ///
    enum CardPaymentReadiness {
        /// Current state is being fetched
        case loading

        /// Onboarding has been successfully completed, and reader connection can be triggered.
        /// N.B. A reader may already be connected.
        case ready

        /// Onboarding is in an incomplete/error state, so should be displayed instead of attempting a reader connection
        case onboardingRequired
    }

    @Published var readiness: CardPaymentReadiness = .loading

    /// Observes the store's current CPP state.
    ///
    private let onboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private let stores: StoresManager

    init(onboardingUseCase: CardPresentPaymentsOnboardingUseCase,
         stores: StoresManager = ServiceLocator.stores) {
        self.onboardingUseCase = onboardingUseCase
        self.stores = stores
    }

    /// Checks whether there is a reader connected (implying that we're ready to accept payments)
    /// If there's not, checks whether `CardPresentOnboardingState` is `.completed`
    ///
    func checkCardPaymentReadiness() {
        onboardingUseCase.refresh()
        let readerConnected = CardPresentPaymentAction.checkCardReaderConnected { connectPublisher in
            // TODO: Use readerConnectedReadiness to preempt the onboarding readiness check.
            // This requires a refactor of `checkCardReaderConnected` to emit an event for a connected reader.
            let readerConnectedReadiness = connectPublisher.map { _ -> CardPaymentReadiness in
                return CardPaymentReadiness.loading
            }

            let onboardingReadiness = self.onboardingUseCase.statePublisher
                .compactMap({ state -> CardPaymentReadiness? in
                    switch state {
                    case .loading:
                        // Ignoring intermediate loading steps simplifies the logic
                        return nil
                    case .completed:
                        return CardPaymentReadiness.ready
                    default:
                        return CardPaymentReadiness.onboardingRequired
                    }
                })
                .removeDuplicates()

            readerConnectedReadiness
                .merge(with: onboardingReadiness)
                .removeDuplicates()
                .assign(to: &self.$readiness)
        }
        stores.dispatch(readerConnected)
    }
}
