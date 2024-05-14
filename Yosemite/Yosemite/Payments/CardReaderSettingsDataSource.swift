import Foundation
import protocol Storage.StorageManagerType

public class CardReaderSettingsDataSource: NSObject {
    /// This is only used to pass as a dependency to `CardReaderSettingsResultsControllers`.
    private let storageManager: StorageManagerType

    private let siteID: Int64

    private lazy var resultsControllers: CardReaderSettingsResultsControllers = {
        return CardReaderSettingsResultsControllers(siteID: self.siteID, storageManager: self.storageManager)
    }()

    public init(siteID: Int64, storageManager: StorageManagerType) {
        self.storageManager = storageManager
        self.siteID = siteID
        super.init()
    }

    public func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }

    public func cardPresentPaymentGatewayID() -> String? {
        let filteredAccounts = resultsControllers.paymentGatewayAccounts.filter { $0.isCardPresentEligible }

        guard let account = filteredAccounts.first else {
            return nil
        }

        return account.gatewayID
    }
}
