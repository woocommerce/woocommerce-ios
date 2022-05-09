import Foundation
import Combine
import Yosemite

final class CardPresentPaymentsReadinessUseCase {
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

    private var cancellables: [AnyCancellable] = []

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
            let readerConnectedReadiness = connectPublisher
                .map { readers -> CardPaymentReadiness in
                    if readers.isNotEmpty {
                        return .ready
                    } else {
                        /// Since there are no readers connected, we'll load the onboarding state
                        return .loading
                    }
                }
                .removeDuplicates()
                .share()

            readerConnectedReadiness.sink { [weak self] readiness in
                if case .loading = readiness {
                    self?.onboardingUseCase.forceRefresh()
                }
            }
            .store(in: &self.cancellables)

            let onboardingReadiness = self.onboardingUseCase.statePublisher
                .compactMap({ state -> CardPaymentReadiness? in
                    switch state {
                    case .loading:
                        /// Ignoring intermediate loading steps simplifies the logic.
                        /// We already know about initial loading from the readerConnectedReadiness stream
                        return nil
                    case .completed:
                        return .ready
                    default:
                        return .onboardingRequired
                    }
                })

            readerConnectedReadiness
                .merge(with: onboardingReadiness)
                .removeDuplicates()
                .assign(to: &self.$readiness)
        }
        stores.dispatch(readerConnected)
    }
}
