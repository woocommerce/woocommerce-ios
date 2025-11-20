import Foundation
import UIKit
import SwiftUI
import Yosemite
import class WooFoundation.CurrencySettings
import WooFoundationCore
import protocol Storage.GRDBManagerProtocol
import protocol Storage.StorageManagerType
import class WooFoundationCore.CurrencyFormatter
import struct NetworkingCore.JetpackSite
import struct NetworkingCore.OrderItem
import struct Combine.AnyPublisher
import PointOfSale

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

    private lazy var posSyncDispatcher = ForegroundPOSCatalogSyncDispatcher()

    /// Local catalog eligibility service - created asynchronously during init
    private(set) var localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?

    private lazy var posItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory = {
        PointOfSaleItemFetchStrategyFactory(siteID: siteID,
                                            credentials: credentials,
                                            selectedSite: defaultSitePublisher,
                                            appPasswordSupportState: isAppPasswordSupported)
    }()

    private lazy var posPopularItemFetchStrategyFactory: PointOfSaleFixedItemFetchStrategyFactory = {
        PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: posItemFetchStrategyFactory.popularStrategy())
    }()

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
         localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?) {
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

        tabContainerController.wrappedController = POSTabViewController()
    }

    /// Check and update POS eligibility for local catalog
    /// Only checks eligibility if the POS tab is visible
    func updatePOSEligibility(isPOSTabVisible: Bool) {
        Task { @MainActor [weak self] in
            guard let self, let catalogEligibilityService = self.localCatalogEligibilityService else { return }

            // If POS tab is not visible, mark as ineligible
            guard isPOSTabVisible else {
                try await catalogEligibilityService.updatePOSEligibility(isEligible: false,
                                                                         for: siteID)
                await posSyncDispatcher.stop()
                return
            }

            // Check actual POS eligibility using the eligibility checker
            let eligibilityState = await eligibilityChecker.checkEligibility()
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

    func onTabSelected() {
        setPOSHasBeenOpened()
        presentPOSView(siteID: siteID)
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

    func presentPOSView(siteID: Int64) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            // Get local catalog eligibility as bool from service
            let isLocalCatalogEligible: Bool
            if let service = localCatalogEligibilityService {
                // Retry transient failures before using the value
                let state = try await service.catalogEligibility(for: siteID)
                if case .ineligible(reason: .catalogSizeCheckFailed) = state {
                    try await service.refreshEligibilityState(for: siteID)
                }
                isLocalCatalogEligible = try await service.catalogEligibility(for: siteID) == .eligible
            } else {
                // Service not ready yet (rare race condition), assume ineligible
                isLocalCatalogEligible = false
            }

            let serviceAdaptor = POSServiceLocatorAdaptor()
            let collectPaymentAnalyticsAdaptor = POSCollectOrderPaymentAnalyticsAdaptor(analytics: serviceAdaptor.analytics)

            // Use mock card payment service for screenshot tests
            let cardPresentPaymentService: CardPresentPaymentFacade
            if ProcessConfiguration.shouldBypassCardPresentPayment {
                cardPresentPaymentService = CardPresentPaymentServiceScreenshotMock()
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

            // Only initialize local catalog infrastructure if eligible
            let grdbManager: GRDBManagerProtocol? = isLocalCatalogEligible ? ServiceLocator.grdbManager : nil
            let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = isLocalCatalogEligible ? ServiceLocator.posCatalogSyncCoordinator : nil

            // Create appropriate barcode scan service based on local catalog eligibility
            // Will use local GRDB-based scanning if eligible and infrastructure is available,
            // otherwise falls back to remote API-based scanning
            let barcodeScanService = createBarcodeScanService(isLocalCatalogEligible: isLocalCatalogEligible,
                                                              grdbManager: grdbManager)

            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials,
                                                      selectedSite: defaultSitePublisher,
                                                      appPasswordSupportState: isAppPasswordSupported) {

                // Use mock order service for screenshot tests to bypass network calls
                let orderService: POSOrderServiceProtocol
                if ProcessConfiguration.shouldBypassPOSOrderSyncing {
                    orderService = POSOrderServiceScreenshotMock(currency: currencySettings.currencyCode.rawValue)
                } else if let realService = POSOrderService(siteID: siteID,
                                                           credentials: credentials,
                                                           selectedSite: defaultSitePublisher,
                                                           appPasswordSupportState: isAppPasswordSupported) {
                    orderService = realService
                } else {
                    return
                }

                var itemProvider: Yosemite.PointOfSaleItemServiceProtocol? = nil
                if ProcessConfiguration.shouldLoadMockedPOSProducts {
                    itemProvider = PointOfSaleItemServiceScreenshotMock()
                }

                let posView = PointOfSaleEntryPointView(
                    siteID: siteID,
                    itemFetchStrategyFactory: posItemFetchStrategyFactory,
                    popularItemFetchStrategyFactory: posPopularItemFetchStrategyFactory,
                    couponProvider: posCouponProvider,
                    couponFetchStrategyFactory: posCouponFetchStrategyFactory,
                    orderListFetchStrategyFactory: POSOrderListFetchStrategyFactory(
                        siteID: siteID,
                        credentials: credentials,
                        selectedSite: defaultSitePublisher,
                        appPasswordSupportState: isAppPasswordSupported,
                        currencyFormatter: CurrencyFormatter(currencySettings: currencySettings),
                        analytics: POSOrderListFetchAnalytics(analytics: serviceAdaptor.analytics)
                    ),
                    orderService: orderService,
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
                    services: serviceAdaptor,
                    itemProvider: itemProvider
                )

                let hostingController = UIHostingController(rootView: posView)
                hostingController.modalPresentationStyle = .fullScreen
                viewControllerToPresent.present(hostingController, animated: true)
            }
        }
    }
}

private extension POSTabCoordinator {
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

/// Mock order service for screenshot tests that returns immediate loaded state
private final class POSOrderServiceScreenshotMock: POSOrderServiceProtocol {
    private let currency: String

    init(currency: String) {
        self.currency = currency
    }

    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        // Create a mock order with totals calculated from the cart
        // For screenshot tests with 2 products: $35.00 + $45.00 = $80.00
        let orderItems = [
            OrderItem(
                itemID: 1,
                name: "Product 1",
                productID: 1,
                variationID: 0,
                quantity: 1,
                price: NSDecimalNumber(string: "35.00"),
                sku: nil,
                subtotal: "35.00",
                subtotalTax: "0.00",
                taxClass: "",
                taxes: [],
                total: "35.00",
                totalTax: "0.00",
                attributes: [],
                addOns: [],
                image: nil,
                parent: nil,
                bundleConfiguration: []
            ),
            OrderItem(
                itemID: 2,
                name: "Product 2",
                productID: 2,
                variationID: 0,
                quantity: 1,
                price: NSDecimalNumber(string: "45.00"),
                sku: nil,
                subtotal: "45.00",
                subtotalTax: "0.00",
                taxClass: "",
                taxes: [],
                total: "45.00",
                totalTax: "0.00",
                attributes: [],
                addOns: [],
                image: nil,
                parent: nil,
                bundleConfiguration: []
            )
        ]

        let total = "80.00"
        let tax = "0.00"

        return Order(siteID: 0,
                    orderID: 1,
                    parentID: 0,
                    customerID: 0,
                    orderKey: "",
                    isEditable: true,
                    needsPayment: true,
                    needsProcessing: true,
                    number: "1",
                    status: .pending,
                    currency: currency.rawValue,
                    currencySymbol: "$",
                    customerNote: nil,
                    dateCreated: Date(),
                    dateModified: Date(),
                    datePaid: nil,
                    discountTotal: "0.00",
                    discountTax: "0.00",
                    shippingTotal: "0.00",
                    shippingTax: "0.00",
                    total: total,
                    totalTax: tax,
                    paymentMethodID: "",
                    paymentMethodTitle: "",
                    paymentURL: nil,
                    chargeID: nil,
                    items: orderItems,  // Necessary for the card payment flow to be presented in POS
                    billingAddress: nil,
                    shippingAddress: nil,
                    shippingLines: [],
                    coupons: [],
                    refunds: [],
                    fees: [],
                    taxes: [],
                    customFields: [],
                    renewalSubscriptionID: nil,
                    appliedGiftCards: [],
                    attributionInfo: nil,
                    shippingLabels: [],
                    createdVia: "pos")
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {}

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {}
}


private final class PointOfSaleItemServiceScreenshotMock: Yosemite.PointOfSaleItemServiceProtocol {

    func providePointOfSaleItems(pageNumber: Int,
                                 fetchStrategy: Yosemite.PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<Yosemite.POSItem> {
        let port = UserDefaults.standard.integer(forKey: "mocks-port")
        let mockResourceUrlHost = "http://localhost:\(port)/"

        let mockItems = Self.makeScreenshotMockItems(mockResourceUrlHost: mockResourceUrlHost)

        return PagedItems(items: mockItems, hasMorePages: false, totalItems: mockItems.count)
    }

    func providePointOfSaleVariationItems(for parentProduct: Yosemite.POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: Yosemite.PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<Yosemite.POSItem> {
        // Not needed for screenshot tests, return empty
        return PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    private static func makeScreenshotMockItems(mockResourceUrlHost: String) -> [Yosemite.POSItem] {
        let product1 = Yosemite.POSSimpleProduct(
            id: UUID(),
            name: "Rose Gold Shades",
            formattedPrice: "$35.00",
            productImageSource: mockResourceUrlHost + "rose-gold-shades",
            productID: 1,
            price: "35.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        let product2 = Yosemite.POSSimpleProduct(
            id: UUID(),
            name: "Black Coral Shades",
            formattedPrice: "$45.00",
            productImageSource: mockResourceUrlHost + "black-coral-shades",
            productID: 2,
            price: "45.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        let product3 = Yosemite.POSSimpleProduct(
            id: UUID(),
            name: "Akoya Pearl Shades",
            formattedPrice: "$50.00",
            productImageSource: mockResourceUrlHost + "akoya-pearl-shades",
            productID: 3,
            price: "50.00",
            manageStock: true,
            stockQuantity: 10,
            stockStatusKey: "instock"
        )

        let product4 = Yosemite.POSSimpleProduct(
            id: UUID(),
            name: "Malaya Shades",
            formattedPrice: "$40.00",
            productImageSource: mockResourceUrlHost + "malaya-shades",
            productID: 4,
            price: "40.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        return [
            .simpleProduct(product1),
            .simpleProduct(product2),
            .simpleProduct(product3),
            .simpleProduct(product4)
        ]
    }
}
