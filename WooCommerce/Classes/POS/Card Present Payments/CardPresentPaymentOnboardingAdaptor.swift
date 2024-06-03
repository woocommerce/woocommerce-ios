import Foundation
import Combine
import protocol Yosemite.StoresManager

/// This is really a re-implementation of the CardPresentPaymentsOnboardingPresenter, as it needs to take the calls to `showOnboardingIfRequired` and
/// route the output to a SwiftUI view for display, rather than directly displaying on the viewController that's passed in.
final class CardPresentPaymentsOnboardingPresenterAdaptor: CardPresentPaymentsOnboardingPresenting {
    private let onboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private let readinessUseCase: CardPresentPaymentsReadinessUseCase

    private let onboardingViewModel: CardPresentPaymentsOnboardingViewModel

    private var readinessSubscription: AnyCancellable?

    let onboardingScreenViewModelPublisher: AnyPublisher<CardPresentPaymentOnboardingPresentationEvent, Never>

    private let onboardingScreenViewModelSubject: PassthroughSubject<CardPresentPaymentOnboardingPresentationEvent, Never> = PassthroughSubject()

    init(stores: StoresManager = ServiceLocator.stores) {
        onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)
        readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)
        onboardingViewModel = CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase)
        onboardingScreenViewModelPublisher = onboardingScreenViewModelSubject.eraseToAnyPublisher()
    }

    /// If the onboarding state is not `ready`, this will instruct downstream SwiftUI code to present the onboarding screen.
    /// The CardPresentPaymentOnboardingView controls which message will be shown based on the view model we pass, which will change over time.
    /// - Parameters:
    ///   - viewController: This will be ignored, as other SwiftUI code is responsible for the display in this implementation.
    ///   - completion: Callback when the onboarding is complete
    func showOnboardingIfRequired(from viewController: ViewControllerPresenting,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        guard readinessSubscription == nil else {
            return
        }

        readinessUseCase.checkCardPaymentReadiness()

        guard case .ready = readinessUseCase.readiness else {
            return showOnboarding(readyToCollectPayment: completion)
        }

        completion()
    }

    private func showOnboarding(readyToCollectPayment completion: @escaping () -> Void) {
        onboardingScreenViewModelSubject.send(.showOnboarding(onboardingViewModel))

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
