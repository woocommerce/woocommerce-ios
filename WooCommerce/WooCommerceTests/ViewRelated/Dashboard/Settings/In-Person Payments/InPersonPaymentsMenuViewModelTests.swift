import SwiftUI
import XCTest
import TestKit
import protocol WooFoundation.Analytics
@testable import Yosemite
@testable import WooCommerce

/// Temporarily removed pending a rewrite for the new InPersonPaymentsMenuViewModel #11168
@MainActor
final class InPersonPaymentsMenuViewModelTests: XCTestCase {

    private var sut: InPersonPaymentsMenuViewModel!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var mockDepositService: MockWooPaymentsDepositService!
    private var mockOnboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!
    private var mockPayInPersonToggleViewModel: MockInPersonPaymentsCashOnDeliveryToggleRowViewModel!

    private let sampleStoreID: Int64 = 12345

    private var systemStatusService: MockSystemStatusService!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        mockDepositService = MockWooPaymentsDepositService()
        mockOnboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .completed(plugin: .wcPayOnly))
        mockPayInPersonToggleViewModel = MockInPersonPaymentsCashOnDeliveryToggleRowViewModel()
        systemStatusService = MockSystemStatusService()
        systemStatusService.onFetchSystemPluginWithPath = { _ in
            return .fake()
        }
        sut = makeSut()
    }

    func makeSut() -> InPersonPaymentsMenuViewModel {
        InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                      dependencies: .init(
                                        cardPresentPaymentsConfiguration: .init(country: .US),
                                        onboardingUseCase: mockOnboardingUseCase,
                                        cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                        wooPaymentsDepositService: mockDepositService,
                                        systemStatusService: systemStatusService,
                                        analytics: analytics),
                                      navigationPath: .constant(.init()),
                                      payInPersonToggleViewModel: mockPayInPersonToggleViewModel)
    }

    func test_fetchDepositsOverview_is_not_called_for_stores_which_do_not_support_the_route() async {
        // Currently, assume this is only WooPayments stores, but it would be better to check the /wc/v3 base endpoint.
        // Given
        systemStatusService.onFetchSystemPluginWithPath = { _ in
            return nil
        }

        // When
        await sut.onAppear()

        // Then
        XCTAssertFalse(mockDepositService.spyDidCallFetchDepositsOverview)
    }

    func test_fetchDepositsOverview_is_called_for_stores_which_support_the_route() async {
        // Currently, assume this is only WooPayments stores, but it would be better to check the /wc/v3 base endpoint.
        // Given
        systemStatusService.onFetchSystemPluginWithPath = { path in
            guard path == "woocommerce-payments/woocommerce-payments.php" else {
                return nil
            }
            return .fake().copy(siteID: self.sampleStoreID, plugin: "woocommerce-payments/woocommerce-payments.php")
        }

        // When
        await sut.onAppear()

        // Then
        XCTAssert(mockDepositService.spyDidCallFetchDepositsOverview)
    }

     func test_onAppear_refreshesPayInPersonToggle() async {
         // Given
         mockPayInPersonToggleViewModel.spyDidCallRefreshState = false

         // When
         await sut.onAppear()

         // Then
         XCTAssertTrue(mockPayInPersonToggleViewModel.spyDidCallRefreshState)
    }

    // MARK: - Analytics tests
    func test_onAppear_when_deposit_service_gets_an_error_depositSummaryError_is_tracked() async {
        // Given
        mockDepositService.onFetchDepositsOverviewShouldThrow = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "description"))

        // When
        await sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryError.rawValue))
    }

    func test_collectPaymentTapped_tracks_paymentsMenuCollectPaymentTapped() {
        // Given

        // When
        sut.collectPaymentTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuCollectPaymentTapped.rawValue))
    }

    func test_setUpTryOutTapToPayTapped_tracks_setUpTryOutTapToPayOnIPhoneTapped() {
        // Given

        // When
        sut.setUpTryOutTapToPayTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.setUpTryOutTapToPayOnIPhoneTapped.rawValue))
    }

    func test_aboutTapToPayTapped_tracks_aboutTapToPayOnIPhoneTapped() {
        // Given

        // When
        sut.aboutTapToPayTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.aboutTapToPayOnIPhoneTapped.rawValue))
    }

    func test_cardReaderManualsTapped_tracks_paymentsMenuCardReadersManualsTapped() {
        // Given

        // When
        sut.cardReaderManualsTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuCardReadersManualsTapped.rawValue))
    }

    func test_manageCardReadersTapped_tracks_paymentsMenuManageCardReadersTapped() {
        // Given

        // When
        sut.manageCardReadersTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuManageCardReadersTapped.rawValue))
    }

     func test_purchaseCardReaderTapped_tracks_paymentsMenuOrderCardReaderTapped() {
         // Given

         // When
         sut.purchaseCardReaderTapped()

         // Then
         XCTAssertTrue(analyticsProvider.receivedEvents.contains("payments_hub_order_card_reader_tapped"))
     }

    func test_managePaymentGatewaysTapped_tracks_paymentsMenuPaymentProviderTapped() {
        // Given

        // When
        sut.managePaymentGatewaysTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPaymentProviderTapped.rawValue))
    }

     func test_purchaseCardReaderTapped_presents_card_reader_purchase_web_view() throws {
         // Given
         XCTAssertNil(sut.safariSheetURL)

         // When
         sut.purchaseCardReaderTapped()

         // Then
         XCTAssertTrue(sut.presentPurchaseCardReader)
         let cardReaderPurchaseURL = try XCTUnwrap(sut.purchaseCardReaderWebViewModel.initialURL)
         assertEqual("https", cardReaderPurchaseURL.scheme)
         assertEqual("woocommerce.com", cardReaderPurchaseURL.host)
         assertEqual("/products/hardware/US", cardReaderPurchaseURL.path)
         let query = try XCTUnwrap(cardReaderPurchaseURL.query)
         XCTAssert(query.contains("utm_medium=woo_ios"))
         XCTAssert(query.contains("utm_campaign=payments_menu_item"))
         XCTAssert(query.contains("utm_source=payments_menu"))
     }

    // MARK: - Tap to Pay tests
     func test_shouldShowTapToPaySection_false_when_built_in_reader_isnt_in_configuration() async {
         // Given
         let configuration = CardPresentPaymentsConfiguration(
             countryCode: .IN,
             paymentMethods: [.cardPresent],
             currencies: [.INR],
             paymentGateways: [WCPayAccount.gatewayID],
             supportedReaders: [.wisepad3],
             supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
             minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
             stripeSmallestCurrencyUnitMultiplier: 100,
             contactlessLimitAmount: nil,
             minimumOperatingSystemVersionForTapToPay: .init(majorVersion: 16, minorVersion: 0, patchVersion: 0))

         let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: configuration,
                                                                       onboardingUseCase: mockOnboardingUseCase,
                                                                       cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                       wooPaymentsDepositService: mockDepositService)
         sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                             dependencies: dependencies,
                                             navigationPath: .constant(.init()))

         // When
         await sut.onAppear()

         // Then
         XCTAssertFalse(sut.shouldShowTapToPaySection)
     }

    func test_shouldShowTapToPaySection_true_when_built_in_reader_in_configuration() async {
        // Given
        let configuration = CardPresentPaymentsConfiguration(
            countryCode: .IN,
            paymentMethods: [.cardPresent],
            currencies: [.INR],
            paymentGateways: [WCPayAccount.gatewayID],
            supportedReaders: [.appleBuiltIn],
            supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
            minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
            stripeSmallestCurrencyUnitMultiplier: 100,
            contactlessLimitAmount: nil,
            minimumOperatingSystemVersionForTapToPay: .init(majorVersion: 16, minorVersion: 0, patchVersion: 0))

        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: configuration,
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsDepositService: mockDepositService)
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies,
                                            navigationPath: .constant(.init()))

        // When
        await sut.onAppear()

        // Then
        XCTAssertFalse(sut.shouldShowTapToPaySection)
    }

    // MARK: - Collect Payment tests

    func test_collectPaymentTapped_appends_collectPayment_to_navigation_path() {
        // Given
        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: .init(country: .US),
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsDepositService: mockDepositService)
        var navigationPath = NavigationPath()
        let navigationPathBinding = Binding<NavigationPath>(
            get: { navigationPath },
            set: { newValue in navigationPath = newValue }
        )
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies,
                                            navigationPath: navigationPathBinding)
        XCTAssertTrue(sut.navigationPath.isEmpty)

        // When
        sut.collectPaymentTapped()

        // Then
        XCTAssertEqual(navigationPath, NavigationPath([InPersonPaymentsMenuNavigationDestination.collectPayment]))
    }

    func test_navigate_to_collectPayment_appends_collectPayment_to_empty_navigation_path() {
        // Given
        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: .init(country: .US),
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsDepositService: mockDepositService)
        var navigationPath = NavigationPath()
        let navigationPathBinding = Binding<NavigationPath>(
            get: { navigationPath },
            set: { newValue in navigationPath = newValue }
        )
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies,
                                            navigationPath: navigationPathBinding)
        XCTAssertTrue(sut.navigationPath.isEmpty)

        // When
        sut.navigate(to: PaymentsMenuDestination.collectPayment)

        // Then
        XCTAssertEqual(navigationPath, NavigationPath([InPersonPaymentsMenuNavigationDestination.collectPayment]))
    }

    func test_navigate_to_collectPayment_appends_collectPayment_to_non_empty_navigation_path() {
        // Given
        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: .init(country: .US),
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsDepositService: mockDepositService)
        var navigationPath = NavigationPath(["testPath"])
        let navigationPathBinding = Binding<NavigationPath>(
            get: { navigationPath },
            set: { newValue in navigationPath = newValue }
        )
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies,
                                            navigationPath: navigationPathBinding)
        XCTAssertEqual(navigationPath, NavigationPath(["testPath"]))

        // When
        sut.navigate(to: PaymentsMenuDestination.collectPayment)

        // Then
        XCTAssertEqual(navigationPath.count, 2)
        let expectedPath = {
            var path = NavigationPath(["testPath"])
            path.append(InPersonPaymentsMenuNavigationDestination.collectPayment)
            return path
        }()
        XCTAssertEqual(navigationPath.codable, expectedPath.codable)
    }

    func test_dismissPaymentCollection_pops_paths_down_to_before_the_first_colletPayment_path() {
        // Given
        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: .init(country: .US),
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsDepositService: mockDepositService)
        var navigationPath = NavigationPath(["testPath"])
        let navigationPathBinding = Binding<NavigationPath>(
            get: { navigationPath },
            set: { newValue in navigationPath = newValue }
        )
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies,
                                            navigationPath: navigationPathBinding)
        XCTAssertEqual(navigationPath, NavigationPath(["testPath"]))

        // When navigating to collectPayment and pushing other views, then dismiss payment collection
        sut.navigate(to: PaymentsMenuDestination.collectPayment)
        navigationPath.append(InPersonPaymentsMenuNavigationDestination.collectPayment)
        navigationPath.append("anotherPath")
        XCTAssertEqual(navigationPath.count, 4)
        sut.dismissPaymentCollection()

        // Then
        XCTAssertEqual(navigationPath.count, 1)
        XCTAssertEqual(navigationPath, NavigationPath(["testPath"]))
    }

    func test_collectPaymentTapped_sets_orderViewModel() throws {
        // Given
        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: .init(country: .US),
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsDepositService: mockDepositService)
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies,
                                            navigationPath: .constant(.init()))
        XCTAssertNil(sut.orderViewModel)

        // When
        sut.collectPaymentTapped()
        XCTAssertNotNil(sut.orderViewModel)
        sut.orderViewModel?.syncRequired = true

        // Then
        let originalOrderViewModel = try XCTUnwrap(sut.orderViewModel)
        XCTAssertTrue(originalOrderViewModel.syncRequired)
    }

    func test_collectPaymentTapped_resets_presentCustomAmountAfterDismissingCollectPaymentMigrationSheet_and_hasPresentedCollectPaymentMigrationSheet_to_false() {
        // Given
        XCTAssertFalse(sut.presentCustomAmountAfterDismissingCollectPaymentMigrationSheet)
        XCTAssertFalse(sut.hasPresentedCollectPaymentMigrationSheet)

        // When
        sut.presentCustomAmountAfterDismissingCollectPaymentMigrationSheet = true
        sut.hasPresentedCollectPaymentMigrationSheet = true
        sut.collectPaymentTapped()

        // Then
        XCTAssertFalse(sut.presentCustomAmountAfterDismissingCollectPaymentMigrationSheet)
        XCTAssertFalse(sut.hasPresentedCollectPaymentMigrationSheet)
    }
}
