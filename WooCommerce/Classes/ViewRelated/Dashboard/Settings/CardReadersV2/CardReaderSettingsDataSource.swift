import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class CardReaderSettingsDataSource: NSObject {
    /// This is only used to pass as a dependency to `CardReaderSettingsResultsControllers`.
    private let storageManager: StorageManagerType

    private let siteID: Int64

    private let instanceID = Int.random(in: 1..<10000)

    private lazy var resultsControllers: CardReaderSettingsResultsControllers = {
        return CardReaderSettingsResultsControllers(siteID: self.siteID, storageManager: self.storageManager)
    }()

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
        self.siteID = siteID
        super.init()
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        print("==== in CardReaderSettingsDataSource \(instanceID) configureResultsControllers")
        resultsControllers.configureResultsControllers(onReload: onReload)
    }

    func cardPresentPaymentGatewayID() -> String {
        let filteredAccounts = resultsControllers.paymentGatewayAccounts.filter { $0.isCardPresentEligible }

        guard let account = filteredAccounts.first else {
            print("==== in CardReaderSettingsDataSource \(instanceID) cardPresentPaymentGatewayID no accounts!")
            return "unknown"
        }

        print("==== in CardReaderSettingsDataSource \(instanceID) cardPresentPaymentGatewayID we have 1 or more accounts")
        return account.gatewayID
    }
}
