import UIKit
import Yosemite
import Combine

final class CardPresentPaymentsOnboardingPresenter {

    private let stores: StoresManager

    private let readinessUseCase: CardPresentPaymentsReadinessUseCase

    private let onboardingViewModel: InPersonPaymentsViewModel

    private var readinessSubscription: AnyCancellable?

    private var subscriptions = [AnyCancellable]()

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        let onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)
        readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)
        onboardingViewModel = InPersonPaymentsViewModel(useCase: onboardingUseCase)
    }

    func showOnboardingIfRequired(from viewController: UIViewController,
                                  readyToCollectPayment completion: @escaping (() -> ())) {
        guard case .ready = readinessUseCase.readiness else {
            return showOnboarding(from: viewController, readyToCollectPayment: completion)
        }
        completion()
    }

    private func showOnboarding(from viewController: UIViewController,
                                readyToCollectPayment completion: @escaping (() -> ())) {
        let onboardingViewController = InPersonPaymentsViewController(viewModel: onboardingViewModel)
        viewController.show(onboardingViewController, sender: viewController)

        readinessSubscription = readinessUseCase.$readiness
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

}
