import Foundation
import Combine
import Yosemite
import protocol Storage.StorageManagerType

/// Use case to collect payments from an order.
/// Orchestrates reader connection, payment, UI alerts and analytics.
///
final class CollectOrderPaymentUseCase {

    /// Store's ID.
    ///
    private let siteID: Int64

    /// Order to collect.
    ///
    private let order: Order

    /// Payment Gateway to use..
    ///
    private let paymentGateway: PaymentGateway

    /// Stores manager.
    ///
    private let stores: StoresManager

    // TODO: Check if I really need this
    /// Storage manager.
    ///
    private let storage: StorageManagerType

    /// Analytics manager,
    ///
    private let analytics: Analytics

    /// View Controller used to present alerts.
    ///
    private var rootViewController: UIViewController

    /// Stores the card reader listener subscription while trying to connect to one.
    ///
    private var readerSubscription: AnyCancellable?

    /// IPP payments collector.
    ///
    private lazy var paymentOrchestrator = PaymentCaptureOrchestrator()

    /// Controller to connect a card reader.
    ///
    private lazy var connectionController = {
        CardReaderConnectionController(forSiteID: siteID,
                                       knownReaderProvider: CardReaderSettingsKnownReaderStorage(), alertsProvider: CardReaderSettingsAlerts())
    }()

    init(siteID: Int64,
         order: Order,
         paymentGateway: PaymentGateway,
         rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.order = order
        self.paymentGateway = paymentGateway
        self.rootViewController = rootViewController
        self.stores = stores
        self.storage = storage
        self.analytics = analytics
    }
}
