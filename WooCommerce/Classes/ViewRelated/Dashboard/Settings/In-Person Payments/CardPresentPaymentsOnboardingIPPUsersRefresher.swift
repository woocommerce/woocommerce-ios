import CoreData
import Yosemite
import Storage

class CardPresentPaymentsOnboardingIPPUsersRefresher {
    private let storageManager: StorageManagerType

    private lazy var ordersResultsController: ResultsController<StorageOrder> = {
        return ResultsController<StorageOrder>(storageManager: storageManager, sortedBy: [])
    }()

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager

        try? ordersResultsController.performFetch()
    }

    func refreshIPPUsersOnboardingState() {
        guard usedIPPBefore() else {
            return
        }

        CardPresentPaymentsOnboardingUseCase.shared.forceRefresh()
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
