import CoreData
import Yosemite
import Storage

/// Refreshes the CPP onboarding state if there are IPP transactions stored
///
class CardPresentPaymentsOnboardingIPPUsersRefresher {
    private let stores: StoresManager
    private let cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol

    init(stores: StoresManager = ServiceLocator.stores,
         cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase()) {
        self.stores = stores
        self.cardPresentPaymentsOnboardingUseCase = cardPresentPaymentsOnboardingUseCase
    }

    func refreshIPPUsersOnboardingState() {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            return
        }

        let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID) { [weak self] result in
            if result {
                self?.cardPresentPaymentsOnboardingUseCase.refresh()
            }
        }

        stores.dispatch(action)
    }
}
