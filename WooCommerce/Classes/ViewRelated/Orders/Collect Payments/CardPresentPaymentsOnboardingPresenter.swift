import UIKit
import Yosemite
import Combine
import Foundation

protocol CardPresentPaymentsOnboardingPresenting {
    func showOnboardingIfRequired(from: ViewControllerPresenting,
                                  readyToCollectPayment: @escaping () -> Void)

    func refresh()
}

/// Checks for the current user status regarding Card Present Payments,
/// and shows the onboarding if the user didn't finish the onboarding to use CPP
///
final class CardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {

    private let stores: StoresManager

    private let onboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private let readinessUseCase: CardPresentPaymentsReadinessUseCase

    private let onboardingViewModel: CardPresentPaymentsOnboardingViewModel

    private var readinessSubscription: AnyCancellable?

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)
        readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)
        onboardingViewModel = CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase)
    }

    func showOnboardingIfRequired(from viewController: ViewControllerPresenting,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        readinessUseCase.checkCardPaymentReadiness()
        guard case .ready = readinessUseCase.readiness else {
            return showOnboarding(from: viewController, readyToCollectPayment: completion)
        }
        completion()
    }

    private func showOnboarding(from viewController: ViewControllerPresenting,
                                readyToCollectPayment completion: @escaping () -> Void) {
        let onboardingViewController = CardPresentPaymentsOnboardingViewController(viewModel: onboardingViewModel,
                                                                                   onWillDisappear: { [weak self] in
            self?.readinessSubscription?.cancel()
        })
        viewController.show(onboardingViewController, sender: viewController)

        readinessSubscription = readinessUseCase.$readiness
            .subscribe(on: DispatchQueue.main)
            .sink(receiveValue: { readiness in
                guard case .ready = readiness else {
                    return
                }

                if let navigationController = viewController as? UINavigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    viewController.navigationController?.popViewController(animated: true)
                }

                completion()
            })
    }

    func refresh() {
        onboardingUseCase.refreshIfNecessary()
    }
}
