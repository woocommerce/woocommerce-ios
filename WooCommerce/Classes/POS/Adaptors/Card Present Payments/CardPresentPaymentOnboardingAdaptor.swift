import Foundation
import PointOfSale
import Combine
import protocol Yosemite.StoresManager
import CocoaLumberjackSwift // WOOMOB-3455 debug repro (REMOVE before commit)

/// This is really a re-implementation of the CardPresentPaymentsOnboardingPresenter, as it needs to take the calls to `showOnboardingIfRequired` and
/// route the output to a SwiftUI view for display, rather than directly displaying on the viewController that's passed in.
final class CardPresentPaymentsOnboardingPresenterAdaptor: CardPresentPaymentsOnboardingPresenting {
    private let onboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private let readinessUseCase: CardPresentPaymentsReadinessUseCase

    private var onboardingViewModel: CardPresentPaymentsOnboardingViewModel {
        CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase)
    }

    private var readinessSubscription: AnyCancellable?

    let onboardingScreenViewModelPublisher: AnyPublisher<CardPresentPaymentOnboardingPresentationEvent, Never>

    private let onboardingScreenViewModelSubject: PassthroughSubject<CardPresentPaymentOnboardingPresentationEvent, Never> = PassthroughSubject()

    init(stores: StoresManager = ServiceLocator.stores) {
        onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)
        readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)
        onboardingScreenViewModelPublisher = onboardingScreenViewModelSubject.eraseToAnyPublisher()
    }

    /// If the onboarding state is not `ready`, this will instruct downstream SwiftUI code to present the onboarding screen.
    /// The CardPresentPaymentOnboardingView controls which message will be shown based on the view model we pass, which will change over time.
    /// - Parameters:
    ///   - viewController: This will be ignored, as other SwiftUI code is responsible for the display in this implementation.
    ///   - completion: Callback when the onboarding is complete
    func showOnboardingIfRequired(from viewController: ViewControllerPresenting,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        // WOOMOB-3455 debug repro (REMOVE before commit): true entry point of the
        // onboarding/readiness check. The branch reached tells us what actually
        // happens per transaction: skipped (already in progress), ready (no screen,
        // but still re-runs checkCardPaymentReadiness), or onboarding shown.
        guard readinessSubscription == nil else {
            DDLogWarn("🧪 [3455] onboarding check SKIPPED — already in progress")
            return
        }

        readinessUseCase.checkCardPaymentReadiness()

        guard case .ready = readinessUseCase.readiness else {
            DDLogWarn("🧪 [3455] onboarding check RAN → not ready, showing onboarding screen")
            return showOnboarding(readyToCollectPayment: completion)
        }

        DDLogWarn("🧪 [3455] onboarding check RAN → ready, no screen (still re-dispatched readiness)")
        completion()
    }

    private func showOnboarding(readyToCollectPayment completion: @escaping () -> Void) {
        let onboardingViewModel = self.onboardingViewModel
        onboardingScreenViewModelSubject.send(.showOnboarding(
            factory: .init(
                configuration: onboardingViewModel,
                view: CardPresentPaymentsOnboardingView(viewModel: onboardingViewModel)),
            onCancel: { [weak self] in
                self?.readinessSubscription = nil
            })
        )

        readinessSubscription = readinessUseCase.$readiness
            .subscribe(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] readiness in
                guard let self,
                      case .ready = readiness else {
                    return
                }

                onboardingScreenViewModelSubject.send(.onboardingComplete)

                completion()

                readinessSubscription = nil
            })
    }

    func refresh() {
        onboardingUseCase.refreshIfNecessary()
    }
}

extension CardPresentPaymentsOnboardingViewModel: CardPresentPaymentsOnboardingViewConfiguration {}
