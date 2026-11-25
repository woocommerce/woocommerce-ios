import Foundation
import UIKit
import SwiftUI
import Yosemite
import Combine
import class WooFoundation.CurrencySettings
import WooFoundationCore
import protocol Storage.GRDBManagerProtocol
import protocol Storage.StorageManagerType
import struct NetworkingCore.JetpackSite
import struct NetworkingCore.OrderItem
import PointOfSale

@MainActor
protocol POSTabVisibilityCheckerProtocol {
    /// Checks the initial visibility of the POS tab.
    func checkInitialVisibility() -> Bool
    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool
}

/// View controller that provides the tab bar item for the Point of Sale tab.
/// It is never visible on the screen, only used to provide the tab bar item as all POS UI is full-screen.
final class POSTabViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarItem.title = NSLocalizedString("pos.tab.title", value: "POS", comment: "Title for the Point of Sale tab.")
        tabBarItem.image = UIImage(systemName: "cart")
        tabBarItem.accessibilityIdentifier = "tab-bar-pos-item"
    }
}

/// Coordinator for the Point of Sale tab.
///
@MainActor
final class POSTabCoordinator {
    private let siteID: Int64
    private let tabContainerController: TabContainerController
    private let viewControllerToPresent: UIViewController
    private let storesManager: StoresManager
    private let credentials: Credentials?
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    private let pushNotesManager: PushNotesManager
    private let eligibilityChecker: POSEntryPointEligibilityCheckerProtocol
    private let httpsConfigurationNoticeProvider: () -> POSHTTPSConfigurationNotice?

    private lazy var posSyncDispatcher = ForegroundPOSCatalogSyncDispatcher()

    /// Local catalog eligibility service - created asynchronously during init
    private let localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?

    /// Main-actor service for the authenticated session. It is attached to the local catalog
    /// actor before that actor evaluates eligibility or starts a sync.
    private let localCatalogSystemStatusService: POSSystemStatusServiceProtocol?

    /// Creates item fetch strategy factory with current local catalog eligibility
    private func createItemFetchStrategyFactory(isLocalCatalogEnabled: Bool) -> PointOfSaleItemFetchStrategyFactory {
        return PointOfSaleItemFetchStrategyFactory(siteID: siteID,
                                                   credentials: credentials,
                                                   selectedSite: defaultSitePublisher,
                                                   appPasswordSupportState: isAppPasswordSupported,
                                                   grdbManager: isLocalCatalogEnabled ? ServiceLocator.grdbManager : nil,
                                                   currencySettings: currencySettings,
                                                   isLocalCatalogEnabled: isLocalCatalogEnabled)
    }

    /// Creates popular item fetch strategy factory with current local catalog eligibility
    private func createPopularItemFetchStrategyFactory(isLocalCatalogEnabled: Bool) -> PointOfSaleFixedItemFetchStrategyFactory {
        let itemFactory = createItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEnabled)
        return PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: itemFactory.popularStrategy())
    }

    private lazy var posCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactory = {
        PointOfSaleCouponFetchStrategyFactory(siteID: siteID,
                                              currencySettings: currencySettings,
                                              credentials: credentials,
                                              selectedSite: defaultSitePublisher,
                                              appPasswordSupportState: isAppPasswordSupported,
                                              storage: storageManager)
    }()

    private lazy var posCouponProvider: PointOfSaleCouponServiceProtocol = {
        return PointOfSaleCouponService(siteID: siteID,
                                        currencySettings: currencySettings,
                                        credentials: credentials,
                                        selectedSite: defaultSitePublisher,
                                        appPasswordSupportState: isAppPasswordSupported,
                                        storage: storageManager)
    }()

    /// Creates the appropriate barcode scan service based on local catalog availability
    private func createBarcodeScanService(isLocalCatalogEligible: Bool,
                                          grdbManager: GRDBManagerProtocol?) -> any PointOfSaleBarcodeScanServiceProtocol {
        if isLocalCatalogEligible,
           let grdbManager {
            return PointOfSaleLocalBarcodeScanService(siteID: siteID,
                                                     grdbManager: grdbManager,
                                                     currencySettings: currencySettings)
        } else {
            // Fall back to remote barcode scanning
            return PointOfSaleBarcodeScanService(siteID: siteID,
                                                credentials: credentials,
                                                selectedSite: defaultSitePublisher,
                                                appPasswordSupportState: isAppPasswordSupported,
                                                currencySettings: currencySettings)
        }
    }

    /// Publisher to send to `AlamofireNetwork` for request authentication mode switching.
    private let defaultSitePublisher: AnyPublisher<JetpackSite?, Never>

    private let appPasswordSupportState: ApplicationPasswordsExperimentState

    /// Publisher to send to `AlamofireNetwork` the state of app password support for JP sites
    private let isAppPasswordSupported: AnyPublisher<Bool, Never>

    init(siteID: Int64,
         tabContainerController: TabContainerController,
         viewControllerToPresent: UIViewController,
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
         eligibilityChecker: POSEntryPointEligibilityCheckerProtocol,
         localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?,
         httpsConfigurationNoticeProvider: @escaping () -> POSHTTPSConfigurationNotice? = { nil }) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.defaultSitePublisher = storesManager.sessionManager.defaultSitePublisher
            .map { $0?.toJetpackSite() }
            .eraseToAnyPublisher()
        self.appPasswordSupportState = ApplicationPasswordsExperimentState()
        self.isAppPasswordSupported = appPasswordSupportState
            .$isAvailableAndEnabled
            .eraseToAnyPublisher()
        self.tabContainerController = tabContainerController
        self.viewControllerToPresent = viewControllerToPresent
        self.credentials = storesManager.sessionManager.defaultCredentials
        self.storageManager = storageManager
        self.currencySettings = currencySettings
        self.pushNotesManager = pushNotesManager
        self.eligibilityChecker = eligibilityChecker
        self.localCatalogEligibilityService = localCatalogEligibilityService
        self.httpsConfigurationNoticeProvider = httpsConfigurationNoticeProvider

        if localCatalogEligibilityService != nil {
            self.localCatalogSystemStatusService = POSSystemStatusService(
                credentials: credentials,
                selectedSite: defaultSitePublisher,
                appPasswordSupportState: isAppPasswordSupported,
                storageManager: storageManager,
                appPasswordSupportStateOwner: appPasswordSupportState
            )
        } else {
            self.localCatalogSystemStatusService = nil
        }

        tabContainerController.wrappedController = POSTabViewController()
    }

    /// Check and update POS eligibility for local catalog
    /// Only checks eligibility if the POS tab is visible
    func updatePOSEligibility(isPOSTabVisible: Bool) {
        Task { @MainActor [weak self] in
            guard let self, let catalogEligibilityService = self.localCatalogEligibilityService else { return }
            await configureLocalCatalogSystemStatusService()

            // If POS tab is not visible, mark as ineligible
            guard isPOSTabVisible else {
                do {
                    try await catalogEligibilityService.updatePOSEligibility(isEligible: false,
                                                                             for: siteID)
                } catch {
                    DDLogError("⛔️ Failed to mark POS as ineligible: \(error)")
                    return
                }
                await posSyncDispatcher.stop()
                return
            }

            // Check actual POS eligibility using the eligibility checker. This is the background
            // re-validation checkpoint (site load and app resume), so it forces a remote check
            // instead of the local state that POS entry can rely on.
            let eligibilityState = await eligibilityChecker.checkEligibility(forceRemoteCheck: true)
            let isPOSEligible = eligibilityState == .eligible
            do {
                try await catalogEligibilityService.updatePOSEligibility(isEligible: isPOSEligible,
                                                                         for: siteID)
                // Only start syncs after we've updated the catalog eligibility.
                await isPOSEligible ? posSyncDispatcher.start() : posSyncDispatcher.stop()
            } catch {
                await posSyncDispatcher.stop()
            }
        }
    }

    func openPOS(entryPoint: POSAnalyticsEntryPoint) {
        TracksProvider.setPOSEntryPoint(entryPoint)
        setPOSHasBeenOpened()
        presentPOSView(siteID: siteID, isReopening: entryPoint == .autoReopen)
    }
}

private extension POSTabCoordinator {
    func setPOSHasBeenOpened() {
        Task { @MainActor in
            let action = AppSettingsAction.setHasPOSBeenOpenedAtLeastOnce { _ in }
            storesManager.dispatch(action)

            // Track last opened date for sync eligibility
            let lastOpenedAction = AppSettingsAction.setPOSLastOpenedDate(siteID: siteID, date: Date()) {}
            storesManager.dispatch(lastOpenedAction)
        }
    }

    func presentPOSView(siteID: Int64, isReopening: Bool) {
        guard viewControllerToPresent.presentedViewController == nil else { return }
        let preparation = POSPreparation()
        let hostingController = POSHostingController(rootView: AnyView(PointOfSaleLoadingEntryPointView()))
        let services = POSServiceLocatorAdaptor()
        let prepare: @MainActor () async -> Void = { [weak self, weak hostingController] in
            guard let self, let hostingController else { return }
            let httpsConfigurationNotice = httpsConfigurationNoticeProvider()
            await configureLocalCatalogSystemStatusService()
            guard !Task.isCancelled else { return }

            // Get local catalog eligibility as bool from service
            let isLocalCatalogEligible: Bool
            if let service = localCatalogEligibilityService {
                // Resolve POS eligibility before deciding the fetch strategy
                let eligibility = await eligibilityChecker.checkEligibility(forceRemoteCheck: false)
                try? await service.updatePOSEligibility(isEligible: eligibility == .eligible, for: siteID)

                // Retry transient failures before using the value
                do {
                    let state = try await service.catalogEligibility(for: siteID)
                    if case .ineligible(reason: .versionCheckFailed) = state {
                        try await service.refreshEligibilityState(for: siteID)
                    }
                    isLocalCatalogEligible = try await service.catalogEligibility(for: siteID) == .eligible
                } catch {
                    DDLogError("⛔️ Failed to resolve local catalog eligibility: \(error)")
                    preparation.state = .unavailable
                    return
                }
            } else {
                // Service not ready yet (rare race condition), assume ineligible
                isLocalCatalogEligible = false
            }

            let grdbManager: GRDBManagerProtocol? = isLocalCatalogEligible ? ServiceLocator.grdbManager : nil
            let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = isLocalCatalogEligible ? ServiceLocator.posCatalogSyncCoordinator : nil

            let catalogSyncStrategy = POSCheckoutCatalogStrategy(isLocalCatalogEligible: isLocalCatalogEligible,
                                                                hasDatabase: grdbManager != nil,
                                                                hasSyncCoordinator: catalogSyncCoordinator != nil)
            let collectPaymentAnalyticsAdaptor = POSCollectOrderPaymentAnalyticsAdaptor(analytics: services.analytics,
                                                                                      catalogSyncStrategy: catalogSyncStrategy)

            let cardPresentPaymentService: CardPresentPaymentFacade
            if ProcessConfiguration.shouldUseMockCardPresentPayment {
                #if DEBUG
                if ProcessConfiguration.shouldUsePOSUITestMocks {
                    cardPresentPaymentService = CardPresentPaymentServiceUITestMock()
                } else {
                    cardPresentPaymentService = CardPresentPaymentServiceScreenshotMock()
                }
                #else
                cardPresentPaymentService = CardPresentPaymentServiceScreenshotMock()
                #endif
            } else {
                cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID,
                                                                            stores: storesManager,
                                                                            collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor)
            }
            let settingsService = PointOfSaleSettingsService(siteID: siteID,
                                                             credentials: credentials,
                                                             selectedSite: defaultSitePublisher,
                                                             appPasswordSupportState: isAppPasswordSupported,
                                                             storage: storageManager)
            let pluginsService = PluginsService(storageManager: storageManager)
            let siteTimezone = storesManager.sessionManager.defaultSite?.siteTimezone ?? .current

            // Create appropriate barcode scan service based on local catalog eligibility
            // Will use local GRDB-based scanning if eligible and infrastructure is available,
            // otherwise falls back to remote API-based scanning
            let barcodeScanService = createBarcodeScanService(isLocalCatalogEligible: isLocalCatalogEligible,
                                                              grdbManager: grdbManager)
            let refundsService = POSRefundsService(siteID: siteID,
                                                   credentials: credentials,
                                                   selectedSite: defaultSitePublisher,
                                                   appPasswordSupportState: isAppPasswordSupported,
                                                   currencySettings: currencySettings)

            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials,
                                                      selectedSite: defaultSitePublisher,
                                                      appPasswordSupportState: isAppPasswordSupported) {

                let orderService: POSOrderServiceProtocol
                if let mockOrderService = makeMockPOSOrderService(currency: currencySettings.currencyCode.rawValue) {
                    orderService = mockOrderService
                } else if let posOrderService = POSOrderService(siteID: siteID,
                                                           credentials: credentials,
                                                           selectedSite: defaultSitePublisher,
                                                           appPasswordSupportState: isAppPasswordSupported) {
                    orderService = posOrderService
                } else {
                    DDLogError("POSOrderService not provided")
                    preparation.state = .unavailable
                    return
                }

                let itemProvider = makeMockPOSItemProvider()

                let receiptSettingsAdminURL = storesManager.sessionManager.defaultSite?.receiptSettingsAdminURL ?? ""

                // Resolve TTP eligibility once, up front, so we can hand the right
                // preferred method down to POSPaymentModel. The same checker is also
                // passed in for the availability controller that drives the buttons /
                // hero, but POSPaymentModel needs the answer synchronously to know
                // whether to skip the BT auto-collect on checkout entry.
                let tapToPayAvailabilityChecker = POSTapToPayAvailabilityChecker(
                    siteID: siteID,
                    countryCode: SiteAddress(siteSettings: ServiceLocator.selectedSiteSettings.siteSettings).countryCode,
                    eligibilityService: POSEligibilityService()
                )
                let preferredConnectionMethod: CardReaderConnectionMethod
                switch await tapToPayAvailabilityChecker.checkAvailability() {
                case .available:
                    preferredConnectionMethod = .tapToPay
                case .unknown, .unavailable:
                    preferredConnectionMethod = .bluetooth
                }

                let refundService: RefundServiceProtocol
                if let mockRefundService = makeMockPOSRefundService(orderService: orderService) {
                    refundService = mockRefundService
                } else if let posRefundService = RefundService(credentials: credentials,
                                                              selectedSite: defaultSitePublisher,
                                                              appPasswordSupportState: isAppPasswordSupported,
                                                              storageManager: storageManager) {
                    refundService = posRefundService
                } else {
                    DDLogError("RefundService not provided")
                    preparation.state = .unavailable
                    return
                }

                let refundFlowResolver = RefundFlowResolver(stores: storesManager,
                                                            availabilityCache: .shared,
                                                            minimumWooVersion: RefundFlowResolver.Constants.minimumWooVersionForServerRefunds)
                let serverRefundPreviewUseCase = ServerRefundPreviewUseCase(refundService: refundService,
                                                                            flowResolver: refundFlowResolver,
                                                                            availabilityCache: .shared,
                                                                            analytics: ServiceLocator.analytics,
                                                                            serverFlowUnavailableEvent: .PointOfSale.refundServerFlowUnavailable())
                let refundSubmissionProcessor = POSRefundSubmissionAdaptor(orderService: orderService,
                                                                           refundService: refundService,
                                                                           stores: storesManager,
                                                                           storageManager: storageManager,
                                                                           currencySettings: currencySettings,
                                                                           serverRefundPreviewUseCase: serverRefundPreviewUseCase)

                let receiptPrinter: ReceiptPrinterServiceProtocol? = ServiceLocator.featureFlagService
                    .isFeatureFlagEnabled(.starReceiptPrinterSupport) ? ServiceLocator.posReceiptPrinterService : nil

                let posView = PointOfSaleEntryPointView(
                    siteID: siteID,
                    itemFetchStrategyFactory: createItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEligible),
                    popularItemFetchStrategyFactory: createPopularItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEligible),
                    couponProvider: posCouponProvider,
                    couponFetchStrategyFactory: posCouponFetchStrategyFactory,
                    orderListFetchStrategyFactory: POSOrderListFetchStrategyFactory(
                        siteID: siteID,
                        credentials: credentials,
                        selectedSite: defaultSitePublisher,
                        appPasswordSupportState: isAppPasswordSupported,
                        currencyFormatter: CurrencyFormatter(currencySettings: currencySettings),
                        analytics: POSOrderListFetchAnalytics(analytics: services.analytics)
                    ),
                    orderService: orderService,
                    refundsService: refundsService,
                    refundSubmissionProcessor: refundSubmissionProcessor,
                    onPointOfSaleModeActiveStateChange: { [weak self] isEnabled in
                        self?.updateDefaultConfigurationForPointOfSale(isEnabled)
                    },
                    cardPresentPaymentService: cardPresentPaymentService,
                    receiptService: receiptService,
                    pluginsService: pluginsService,
                    settingsService: settingsService,
                    collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor,
                    searchHistoryService: POSSearchHistoryService(siteID: siteID),
                    barcodeScanService: barcodeScanService,
                    posEligibilityChecker: eligibilityChecker,
                    siteTimezone: siteTimezone,
                    defaultSiteName: storesManager.sessionManager.defaultSite?.name,
                    siteSettings: ServiceLocator.selectedSiteSettings.siteSettings,
                    grdbManager: grdbManager,
                    catalogSyncCoordinator: catalogSyncCoordinator,
                    isLocalCatalogEligible: isLocalCatalogEligible,
                    receiptSettingsAdminURL: receiptSettingsAdminURL,
                    tapToPayAvailabilityChecker: tapToPayAvailabilityChecker,
                    preferredConnectionMethod: preferredConnectionMethod,
                    receiptPrinter: receiptPrinter,
                    services: services,
                    httpsConfigurationNotice: httpsConfigurationNotice,
                    itemProvider: itemProvider,
                    registerOnDismiss: { [weak hostingController] cleanup in
                        guard let hostingController,
                              !hostingController.isBeingDismissed,
                              hostingController.presentingViewController != nil else { return false }
                        hostingController.onDismiss = cleanup
                        return true
                    }
                )

                guard !Task.isCancelled, hostingController.presentingViewController != nil else { return }
                preparation.state = .ready(posView)
            } else {
                preparation.state = .unavailable
            }
        }

        hostingController.rootView = AnyView(POSLaunchView(siteID: siteID, featureFlags: services.featureFlags, isReopening: isReopening, registerSession: {
            [weak hostingController] context, endSession in
            guard let hostingController, !hostingController.isBeingDismissed, hostingController.presentingViewController != nil else { return false }
            hostingController.accessContext = context
            hostingController.endSession = endSession
            return true
        }) { [weak hostingController] in
            POSPresentationRootView(preparation: preparation, prepare: prepare) {
                hostingController?.dismiss(animated: true)
            }
        })
        hostingController.modalPresentationStyle = .fullScreen
        viewControllerToPresent.present(hostingController, animated: !isReopening)
    }
}


/// Temporary payment coverage must not end the POS presentation.
final class POSHostingController: UIHostingController<AnyView> {
    var accessContext: POSExternalViewContext?
    var endSession: (() -> Void)?
    var onDismiss: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isBeingDismissed || presentingViewController == nil else { return }
        let cleanup = onDismiss
        let endSession = self.endSession
        onDismiss = nil
        self.endSession = nil
        accessContext = nil
        endSession?()
        cleanup?()
    }
}


@MainActor
private final class POSPreparation: ObservableObject {
    enum State {
        case loading
        case ready(PointOfSaleEntryPointView)
        case unavailable
    }

    @Published var state: State = .loading
}

private struct POSPresentationRootView: View {
    @ObservedObject var preparation: POSPreparation
    let prepare: @MainActor () async -> Void
    let onExit: () -> Void

    var body: some View {
        switch preparation.state {
        case .loading:
            PointOfSaleLoadingEntryPointView()
                .task { await prepare() }
        case .ready(let posView):
            posView
        case .unavailable:
            POSLaunchIneligibleView(onRefresh: prepare, onExit: onExit)
        }
    }
}


private extension POSTabCoordinator {
    func configureLocalCatalogSystemStatusService() async {
        guard let localCatalogEligibilityService,
              let localCatalogSystemStatusService else {
            return
        }
        await localCatalogEligibilityService.configure(systemStatusService: localCatalogSystemStatusService)
    }

    func makeMockPOSOrderService(currency: String) -> POSOrderServiceProtocol? {
        #if DEBUG
        if ProcessConfiguration.shouldUsePOSUITestMocks {
            return POSOrderServiceUITestMock()
        }
        #endif

        if ProcessConfiguration.shouldBypassPOSOrderSyncing {
            return POSOrderServiceScreenshotMock(currency: currency)
        }

        return nil
    }

    func makeMockPOSRefundService(orderService: POSOrderServiceProtocol) -> RefundServiceProtocol? {
        #if DEBUG
        if ProcessConfiguration.shouldUsePOSUITestMocks {
            return POSRefundServiceMock(orderService: orderService)
        }
        #endif

        if ProcessConfiguration.shouldBypassPOSOrderSyncing {
            return POSRefundServiceMock(orderService: orderService)
        }

        return nil
    }

    func makeMockPOSItemProvider() -> Yosemite.PointOfSaleItemServiceProtocol? {
        #if DEBUG
        if ProcessConfiguration.shouldUsePOSUITestMocks {
            return PointOfSaleItemServiceUITestMock()
        }
        #endif

        if ProcessConfiguration.shouldLoadMockedPOSProducts {
            return PointOfSaleItemServiceScreenshotMock()
        }

        return nil
    }

    func updateDefaultConfigurationForPointOfSale(_ isPointOfSaleActive: Bool) {
        updateInAppNotifications(isPointOfSaleActive)
        updateTrackEventPrefix(isPointOfSaleActive)
    }

    /// Disables foreground in-app notifications when Point of Sale is active.
    func updateInAppNotifications(_ isPointOfSaleActive: Bool) {
        if isPointOfSaleActive {
            pushNotesManager.disableInAppNotifications()
        } else {
            pushNotesManager.enableInAppNotifications()
        }
    }

    /// Decorates track events with a different prefix when Point of Sale is active.
    func updateTrackEventPrefix(_ isPointOfSaleActive: Bool) {
        TracksProvider.setPOSMode(isPointOfSaleActive)
    }
}
