import UIKit
import Yosemite
import Combine
import Foundation

protocol CardPresentPaymentsOnboardingPresenting {
    @MainActor
    func showOnboardingIfRequired(from: ViewControllerPresenting,
                                  readyToCollectPayment: @escaping () -> Void)

    @MainActor
    func refresh()
}

/// Checks for the current user status regarding Card Present Payments,
/// and shows the onboarding if the user didn't finish the onboarding to use CPP
///
final class CardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {

    private let stores: StoresManager

    // Created on first use so the initializer stays nonisolated for its nonisolated callers.
    @MainActor private lazy var onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)

    @MainActor private lazy var readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)

    @MainActor private lazy var onboardingViewModel = CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase)

    private var readinessSubscription: AnyCancellable?

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func showOnboardingIfRequired(from viewController: ViewControllerPresenting,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        readinessUseCase.checkCardPaymentReadiness()
        guard case .ready = readinessUseCase.readiness else {
            return showOnboarding(from: viewController, readyToCollectPayment: completion)
        }
        completion()
    }

    @MainActor
    private func showOnboarding(from viewController: ViewControllerPresenting,
                                readyToCollectPayment completion: @escaping () -> Void) {
        let onboardingViewController = CardPresentPaymentsOnboardingViewController(viewModel: onboardingViewModel,
                                                                                   onWillDisappear: { [weak self] in
            self?.readinessSubscription?.cancel()
        })
        viewController.show(onboardingViewController, sender: viewController)

        readinessSubscription = readinessUseCase.$readiness
            .subscribe(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] readiness in
                guard case .ready = readiness else {
                    return
                }

                self?.hideOnboarding(onboardingViewController)

                completion()

                self?.readinessSubscription = nil
            })
    }

    // The corresponding `show` we used can either push or present the onboardingViewController.
    // This function allows us to hide it in the appropriate way for how it was shown.
    @MainActor
    private func hideOnboarding(_ onboardingViewController: UIViewController) {
        if let navigationController = onboardingViewController.navigationController {
            navigationController.popViewController(animated: true)
        } else if let presentingViewController = onboardingViewController.presentingViewController {
            presentingViewController.dismiss(animated: true)
        }
    }

    @MainActor
    func refresh() {
        onboardingUseCase.refreshIfNecessary()
    }
}
