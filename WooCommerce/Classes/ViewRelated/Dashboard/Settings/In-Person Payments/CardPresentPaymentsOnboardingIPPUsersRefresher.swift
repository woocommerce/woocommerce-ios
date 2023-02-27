import CoreData
import Yosemite
import Storage

/// Refreshes the CPP onboarding state if there are IPP transactions stored
///
class CardPresentPaymentsOnboardingIPPUsersRefresher {
    private let storageManager: StorageManagerType
    private let cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private lazy var ordersResultsController: ResultsController<StorageOrder> = {
        return ResultsController<StorageOrder>(storageManager: storageManager, sortedBy: [])
    }()

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
        self.cardPresentPaymentsOnboardingUseCase = CardPresentPaymentsOnboardingUseCase()

        try? ordersResultsController.performFetch()
    }

    func refreshIPPUsersOnboardingState() {
        guard usedIPPBefore() else {
            return
        }

        cardPresentPaymentsOnboardingUseCase.forceRefresh()
    }
}

private extension CardPresentPaymentsOnboardingIPPUsersRefresher {
    func usedIPPBefore() -> Bool {
        let IPPTransactionsFound = ordersResultsController.fetchedObjects.filter({
            $0.customFields.contains(where: { $0.key == Constants.receiptURLKey })})

            return IPPTransactionsFound.count > 0
    }
}

private extension CardPresentPaymentsOnboardingIPPUsersRefresher {
    enum Constants {
        static let receiptURLKey = "receipt_url"
    }
}
