import Foundation
import Yosemite
import Networking
import Storage
import Combine
import enum NetworkingCore.RequestAuthenticationMode

// MARK: - AuthenticatedState
//
class AuthenticatedState: StoresManagerState {

    var requestAuthenticationMode: RequestAuthenticationMode? {
        network.authenticationMode
    }

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

    private let network: AlamofireNetwork

    private var cancellables: Set<AnyCancellable> = []

    /// POS Catalog Sync Coordinator (session-scoped)
    ///
    private(set) var posCatalogSyncCoordinator: POSCatalogSyncCoordinator?

    /// POS Catalog Eligibility Service (session-scoped)
    /// Created during initialization alongside the sync coordinator
    ///
    var posCatalogEligibilityChecker: POSLocalCatalogEligibilityServiceProtocol?

    // periphery:ignore - keep strong reference to keep the state publisher alive
    private var appPasswordSupportStateHandler: ApplicationPasswordsExperimentState?
    private var appPasswordSupportState: PassthroughSubject<Bool, Never>

    /// Designated Initializer
    ///
    init(credentials: Credentials,
         sessionManager: SessionManagerProtocol,
         isLocalCatalogFeatureFlagEnabled: Bool) {
        let storageManager = ServiceLocator.storageManager

        let site = sessionManager.defaultSitePublisher
            .map { $0?.toJetpackSite() }
            .eraseToAnyPublisher()

        self.appPasswordSupportState = .init()
        self.network = AlamofireNetwork(
            credentials: credentials,
            selectedSite: site,
            appPasswordSupportState: appPasswordSupportState.eraseToAnyPublisher()
        )

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
            FeatureFlagStore(dispatcher: dispatcher,
                            storageManager: storageManager,
                            network: network,
                            overrideStore: ServiceLocator.remoteFeatureFlagOverrideStore),
            InboxNotesStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            JetpackSettingsStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            JustInTimeMessageStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            MediaStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            NotificationCountStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: PListFileStorage()),
            OrderCardPresentPaymentEligibilityStore(
                dispatcher: dispatcher,
                storageManager: storageManager,
                network: network,
            ),
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
            MetaDataStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network),
            BookingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
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
            services.append(JetpackConnectionStore(dispatcher: dispatcher, network: network, siteURL: siteAddress, siteID: WooConstants.placeholderStoreID))
        case .wpcom:
            /// When authenticated with WPCom, the store is used to handle Jetpack setup when a selected site doesn't have Jetpack.
            /// The store will require cookie-nonce auth, which is handled by a `WordPressOrgNetwork`
            /// injected later through the `authenticate` action before any other action is triggered.
            services.append(JetpackConnectionStore(dispatcher: dispatcher))
        }

        self.services = services

        // Initialize POS catalog sync coordinator and eligibility service if feature flag is enabled
        if isLocalCatalogFeatureFlagEnabled,
           let fullSyncService = POSCatalogFullSyncService(credentials: credentials,
                                                           selectedSite: site,
                                                           appPasswordSupportState: appPasswordSupportState.eraseToAnyPublisher(),
                                                           grdbManager: ServiceLocator.grdbManager,
                                                           usesCatalogAPI: ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI)),
           let incrementalSyncService = POSCatalogIncrementalSyncService(
            credentials: credentials,
            selectedSite: site,
            appPasswordSupportState: appPasswordSupportState.eraseToAnyPublisher(),
            grdbManager: ServiceLocator.grdbManager
           ) {
            let posProductsOnlyEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleOnlyProducts)

            // Create eligibility service
            let eligibilityService = POSLocalCatalogEligibilityService(
                catalogSizeChecker: POSCatalogSizeChecker(
                    credentials: credentials,
                    selectedSite: site,
                    appPasswordSupportState: appPasswordSupportState.eraseToAnyPublisher(),
                    posProductsOnlyEnabled: posProductsOnlyEnabled
                ),
                systemStatusService: POSSystemStatusService(
                    credentials: credentials,
                    selectedSite: site,
                    appPasswordSupportState: appPasswordSupportState.eraseToAnyPublisher(),
                    storageManager: ServiceLocator.storageManager
                ),
                isLocalCatalogFeatureFlagEnabled: isLocalCatalogFeatureFlagEnabled,
                remoteFeatureFlagProvider: POSLocalCatalogEligibilityService.makeRemoteFeatureFlagProvider(dispatcher: dispatcher),
                betaFeatureToggleProvider: {
                    await MainActor.run {
                        ServiceLocator.generalAppSettings.betaFeatureEnabled(.posLocalCatalog)
                    }
                }
            )
            posCatalogEligibilityChecker = eligibilityService

            // Create sync coordinator with eligibility service
            posCatalogSyncCoordinator = POSCatalogSyncCoordinator(
                fullSyncService: fullSyncService,
                incrementalSyncService: incrementalSyncService,
                grdbManager: ServiceLocator.grdbManager,
                catalogEligibilityChecker: eligibilityService,
                analytics: ServiceLocator.analytics,
                connectivityObserver: ServiceLocator.connectivityObserver,
                posProductsOnlyEnabled: posProductsOnlyEnabled
            )

            // Note: POS eligibility will be set later by POSTabCoordinator.updatePOSEligibility
            // when the POS tab visibility check completes in MainTabBarController
        } else {
            posCatalogSyncCoordinator = nil
            posCatalogEligibilityChecker = nil
        }

        trackEventRequestNotificationHandler = TrackEventRequestNotificationHandler()
        startListeningToNotifications()
        observeAppPasswordSupportState()
    }

    /// Convenience Initializer
    ///
    convenience init?(sessionManager: SessionManagerProtocol) {
        guard let credentials = sessionManager.defaultCredentials else {
            return nil
        }
        let isLocalCatalogFeatureFlagEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1)
        self.init(credentials: credentials,
                  sessionManager: sessionManager,
                  isLocalCatalogFeatureFlagEnabled: isLocalCatalogFeatureFlagEnabled)
    }

    /// Executed before the current state is deactivated.
    ///
    func willLeave() {
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
        let resetBookingFilters = AppSettingsAction.resetBookingFilters
        ServiceLocator.stores.dispatch([resetStoredProviders,
                                        resetOrdersSettings,
                                        resetProductsSettings,
                                        resetGeneralStoreSettings,
                                        resetBookingFilters])
    }
}

private extension AuthenticatedState {
    func observeAppPasswordSupportState() {
        DispatchQueue.main.async { [self] in
            /// The state needs to be created on the main thread to avoid creating a new ServiceLocator.stores in a different thread.
            /// Without this, race condition can happen.
            let appPasswordSupportStateHandler = ApplicationPasswordsExperimentState()
            self.appPasswordSupportStateHandler = appPasswordSupportStateHandler // strong ref to keep the stream alive
            appPasswordSupportStateHandler
                .$isAvailableAndEnabled
                .receive(on: DispatchQueue.main)
                .sink { [weak self] enabled in
                    self?.appPasswordSupportState.send(enabled)
                }
                .store(in: &cancellables)
        }
    }
}
