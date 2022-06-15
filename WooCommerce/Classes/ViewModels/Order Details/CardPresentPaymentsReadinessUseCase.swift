import Foundation
import Combine
import Yosemite

final class CardPresentPaymentsReadinessUseCase {
    /// Represents the system's readiness to accept a card payment
    ///
    enum CardPaymentReadiness {
        /// Current state is being fetched
        case loading

        /// Onboarding is complete but we haven't connected to a reader yet
        ///
        case connecting

        /// Onboarding has been successfully completed, and reader connection can be triggered.
        /// N.B. A reader may already be connected.
        case ready(CardPresentPaymentsPlugin)

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
        checkCardPaymentReadiness()
    }

    /// Checks whether there is a reader connected (implying that we're ready to accept payments)
    /// If there's not, checks whether `CardPresentOnboardingState` is `.completed`
    ///
    private func checkCardPaymentReadiness() {
        let readerConnected = CardPresentPaymentAction.publishCardReaderConnections { [weak self] connectPublisher in
            guard let self = self else { return }

            let onboardingReadiness = self.onboardingUseCase.statePublisher
                .compactMap({ state -> CardPaymentReadiness? in
                    switch state {
                    case .loading:
                        /// Ignoring intermediate loading steps simplifies the logic.
                        /// We already know about initial loading from the readerConnectedReadiness stream
                        return nil
                    case let .completed(pluginState):
                        return .ready(pluginState.preferred)
                    default:
                        return .onboardingRequired
                    }
                })

            // This would be easier if there was a direct way to read if there's a reader connected right now
            // Instead, this will emit once whether there is a reader connected
            let isReaderConnected = connectPublisher
                .first()
                .map(\.isNotEmpty)

            // The goal here is to make sure that we call a forceRefresh if there is no reader connected
            // *before* we emit any values from onboardingReadiness.
            // By using a flat map, we ensure that the current onboarding state is ignored if we're about
            // to refresh, because forceRefresh sets the state to .loading
            isReaderConnected
                .handleEvents(receiveOutput: { [weak self] isReaderConnected in
                    if !isReaderConnected {
                        self?.onboardingUseCase.forceRefresh()
                    }
                })
                .flatMap { _ in
                    onboardingReadiness
                }
                .assign(to: &self.$readiness)
        }
        stores.dispatch(readerConnected)
    }
}
