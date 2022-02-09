import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class CardReaderSettingsDataSource: NSObject {
    /// This is only used to pass as a dependency to `CardReaderSettingsResultsControllers`.
    private let storageManager: StorageManagerType

    private let siteID: Int64

    private lazy var resultsControllers: CardReaderSettingsResultsControllers = {
        return CardReaderSettingsResultsControllers(siteID: self.siteID, storageManager: self.storageManager)
    }()

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
        self.siteID = siteID
        super.init()
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }

    func cardPresentPaymentGatewayID() -> String {
        let filteredAccounts = resultsControllers.paymentGatewayAccounts.filter { $0.isCardPresentEligible }

        guard let account = filteredAccounts.first else {
            return "unknown"
        }

        return account.gatewayID
    }
}
