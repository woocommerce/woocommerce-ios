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

    /// For tracking events from Networking layer
    ///
    private let trackEventRequestNotificationHandler: TrackEventRequestNotificationHandler

    /// Designated Initializer
    ///
    init(credentials: Credentials) {
        let storageManager = ServiceLocator.storageManager
        let network = AlamofireNetwork(credentials: credentials)

        var services: [ActionsProcessor] = [
            AppSettingsStore(dispatcher: dispatcher,
                             storageManager: storageManager,
                             fileStorage: PListFileStorage(),
                             generalAppSettings: ServiceLocator.generalAppSettings),
            AddOnGroupStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            BlazeStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CouponStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            DataStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            DomainStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            FeatureFlagStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            InAppPurchaseStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            InboxNotesStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            JetpackSettingsStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
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
            ShippingMethodStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SitePostStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SiteStore(dotcomClientID: ApiCredentials.dotcomAppId,
                      dotcomClientSecret: ApiCredentials.dotcomSecret,
                      dispatcher: dispatcher,
                      storageManager: storageManager,
                      network: network),
            StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SubscriptionStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            TaxStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            UserStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            CardPresentPaymentStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    cardReaderService: ServiceLocator.cardReaderService,
                                    cardReaderConfigProvider: ServiceLocator.cardReaderConfigProvider),
            ReceiptStore(dispatcher: dispatcher,
                         storageManager: storageManager,
                         network: network,
                         receiptPrinterService: ServiceLocator.receiptPrinterService,
                         fileStorage: PListFileStorage()),
            AnnouncementsStore(dispatcher: dispatcher,
                               storageManager: storageManager,
                               network: network,
                               fileStorage: PListFileStorage()),
            WordPressSiteStore(network: network, dispatcher: dispatcher),
            StoreOnboardingTasksStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            GoogleAdsStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            MetaDataStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        ]


        if case .wpcom = credentials {
            services.append(contentsOf: [
                AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
                WordPressThemeStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
            ])
        } else {
            DDLogInfo("No WordPress.com auth token found. AccountStore is not initialized.")
        }

        switch credentials {
        case let .wporg(_, _, siteAddress),
             let .applicationPassword(_, _, siteAddress):
            /// Needs Jetpack connection store to handle Jetpack setup for non-Jetpack sites.
            /// `AlamofireNetwork` is used here to handle requests with application password auth.
            services.append(JetpackConnectionStore(dispatcher: dispatcher, network: network, siteURL: siteAddress))
        case .wpcom:
            /// When authenticated with WPCom, the store is used to handle Jetpack setup when a selected site doesn't have Jetpack.
            /// The store will require cookie-nonce auth, which is handled by a `WordPressOrgNetwork`
            /// injected later through the `authenticate` action before any other action is triggered.
            services.append(JetpackConnectionStore(dispatcher: dispatcher))
        }

        self.services = services

        trackEventRequestNotificationHandler = TrackEventRequestNotificationHandler()

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
