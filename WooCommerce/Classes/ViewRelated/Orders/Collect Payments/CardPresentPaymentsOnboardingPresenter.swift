import UIKit
import Yosemite
import Combine

protocol CardPresentPaymentsOnboardingPresenting {
    func showOnboardingIfRequired(from: UIViewController) async -> Void

    func refresh()
}

/// Checks for the current user status regarding Card Present Payments,
/// and shows the onboarding if the user didn't finish the onboarding to use CPP
/// 
final class CardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {

    private let stores: StoresManager

    private let onboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private let readinessUseCase: CardPresentPaymentsReadinessUseCase

    private let onboardingViewModel: InPersonPaymentsViewModel

    private var readinessSubscription: AnyCancellable?

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)
        readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)
        onboardingViewModel = InPersonPaymentsViewModel(useCase: onboardingUseCase)
    }

    func showOnboardingIfRequired(from viewController: UIViewController) async -> Void {
        guard case .ready = readinessUseCase.readiness else {
            return await showOnboarding(from: viewController)
        }
    }

    private func showOnboarding(from viewController: UIViewController) async -> Void {
        let onboardingViewController = await InPersonPaymentsViewController(viewModel: onboardingViewModel,
                                                                      onWillDisappear: { [weak self] in
            self?.readinessSubscription?.cancel()
        })
        await viewController.show(onboardingViewController, sender: viewController)

        readinessSubscription = readinessUseCase.$readiness
            .sink(receiveValue: { readiness in
                guard case .ready = readiness else {
                    return
                }
                Task {
                    if let navigationController = viewController as? UINavigationController {
                        await navigationController.popViewController(animated: true)
                    } else {
                        await viewController.navigationController?.popViewController(animated: true)
                    }
                }
            })
    }

    func refresh() {
        onboardingUseCase.forceRefresh()
    }
}
