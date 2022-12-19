import Foundation
import Yosemite
import Networking
import Storage

// MARK: - AuthenticatedState
//
class AuthenticatedState: StoresManagerState {

    /// Dispatcher: Glues all of the Stores!
    ///
    private let dispatcher = Dispatcher()

    /// Retains all of the active Services
    ///
    private let services: [ActionsProcessor]

    /// NotificationCenter Tokens
    ///
    private var errorObserverToken: NSObjectProtocol?


    /// Designated Initializer
    ///
    init(credentials: any Credentials) {
        let storageManager = ServiceLocator.storageManager
        let network = AlamofireNetwork(credentials: credentials)

        var services: [ActionsProcessor] = [
            AppSettingsStore(dispatcher: dispatcher,
                             storageManager: storageManager,
                             fileStorage: PListFileStorage(),
                             generalAppSettings: ServiceLocator.generalAppSettings),
            AddOnGroupStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CouponStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            DataStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            DomainStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            InAppPurchaseStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            InboxNotesStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            JustInTimeMessageStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            MediaStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            NotificationCountStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: PListFileStorage()),
            OrderCardPresentPaymentEligibilityStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            PaymentStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            PaymentGatewayStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductAttributeStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductAttributeTermStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductReviewStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductCategoryStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ProductTagStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SettingStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SitePostStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SiteStore(dotcomClientID: ApiCredentials.dotcomAppId,
                      dotcomClientSecret: ApiCredentials.dotcomSecret,
                      dispatcher: dispatcher,
                      storageManager: storageManager,
                      network: network),
            StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            TaxClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            UserStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CardPresentPaymentStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    cardReaderService: ServiceLocator.cardReaderService),
            ReceiptStore(dispatcher: dispatcher,
                         storageManager: storageManager,
                         network: network,
                         receiptPrinterService: ServiceLocator.receiptPrinterService,
                         fileStorage: PListFileStorage()),
            AnnouncementsStore(dispatcher: dispatcher,
                               storageManager: storageManager,
                               network: network,
                               fileStorage: PListFileStorage()),
            JetpackConnectionStore(dispatcher: dispatcher)
        ]

        if let credentials = credentials as? WPCOMCredentials {
            services.append(AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, dotcomAuthToken: credentials.authToken))
        }

        self.services = services

        startListeningToNotifications()
    }

    /// Convenience Initializer
    ///
    convenience init?(sessionManager: SessionManagerProtocol) {
        guard let credentials = sessionManager.defaultCredentials else {
            return nil
        }

        self.init(credentials: credentials)
    }

    /// Executed before the current state is deactivated.
    ///
    func willLeave() {
        let pushNotesManager = ServiceLocator.pushNotesManager

        pushNotesManager.unregisterForRemoteNotifications()
        pushNotesManager.resetBadgeCountForAllStores(onCompletion: {})

        resetServices()
    }

    /// Executed whenever the state is activated.
    ///
    func didEnter() { }


    /// Forwards the received action to the Actions Dispatcher.
    ///
    func onAction(_ action: Action) {
        dispatcher.dispatch(action)
    }
}


// MARK: - Private Methods
//
private extension AuthenticatedState {

    /// Starts listening for Notifications
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        errorObserverToken = nc.addObserver(forName: .RemoteDidReceiveJetpackTimeoutError, object: nil, queue: .main) { [weak self] note in
            self?.tunnelTimeoutWasReceived(note: note)
        }
    }

    /// Executed whenever a DotcomError is received (ApplicationLayer). This allows us to have a *main* error handling flow!
    ///
    func tunnelTimeoutWasReceived(note: Notification) {
        ServiceLocator.analytics.track(.jetpackTunnelTimeout)
    }
}


private extension AuthenticatedState {
    func resetServices() {
        let resetStoredProviders = AppSettingsAction.resetStoredProviders(onCompletion: nil)
        let resetOrdersSettings = AppSettingsAction.resetOrdersSettings
        let resetProductsSettings = AppSettingsAction.resetProductsSettings
        let resetGeneralStoreSettings = AppSettingsAction.resetGeneralStoreSettings
        ServiceLocator.stores.dispatch([resetStoredProviders,
                                        resetOrdersSettings,
                                        resetProductsSettings,
                                        resetGeneralStoreSettings])
    }
}
