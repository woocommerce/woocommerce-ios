import Combine
import SwiftUI
import XCTest
import TestKit
import YosemiteTestHelpers
import protocol WooFoundation.Analytics
@testable import Yosemite
@testable import WooCommerce

/// Temporarily removed pending a rewrite for the new InPersonPaymentsMenuViewModel #11168
@MainActor
final class InPersonPaymentsMenuViewModelTests: XCTestCase {

    private var sut: InPersonPaymentsMenuViewModel!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var mockPayoutService: MockWooPaymentsPayoutService!
    private var mockOnboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!
    private var mockPayInPersonToggleViewModel: MockInPersonPaymentsCashOnDeliveryToggleRowViewModel!

    private let sampleStoreID: Int64 = 12345

    private var systemStatusService: MockSystemStatusService!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        mockPayoutService = MockWooPaymentsPayoutService()
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
                                        wooPaymentsPayoutService: mockPayoutService,
                                        systemStatusService: systemStatusService,
                                        analytics: analytics),
                                      payInPersonToggleViewModel: mockPayInPersonToggleViewModel)
    }

    func test_fetchPayoutsOverview_is_not_called_for_stores_which_do_not_support_the_route() async {
        // Currently, assume this is only WooPayments stores, but it would be better to check the /wc/v3 base endpoint.
        // Given
        systemStatusService.onFetchSystemPluginWithPath = { _ in
            return nil
        }

        // When
        await sut.onAppear()

        // Then
        XCTAssertFalse(mockPayoutService.spyDidCallFetchPayoutsOverview)
    }

    func test_fetchPayoutsOverview_is_called_for_stores_which_support_the_route() async {
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
        XCTAssert(mockPayoutService.spyDidCallFetchPayoutsOverview)
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
    func test_onAppear_when_payout_service_gets_an_error_payoutSummaryError_is_tracked() async {
        // Given
        mockPayoutService.onFetchPayoutsOverviewShouldThrow = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "description"))

        // When
        await sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPayoutSummaryError.rawValue))
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
    func test_onAppear_when_missing_country_recovers_then_shows_card_readers_without_recreating_menu() async {
        // Given
        let storage = MockStorageManager()
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(sampleStoreID)
        let settings = SelectedSiteSettings(stores: stores, storageManager: storage)
        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(
            cardPresentPaymentsConfiguration: .init(country: .unknown),
            onboardingUseCase: mockOnboardingUseCase,
            cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
            wooPaymentsPayoutService: nil,
            systemStatusService: systemStatusService,
            stores: stores,
            siteSettings: settings)
        let menu = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                                dependencies: dependencies,
                                                payInPersonToggleViewModel: mockPayInPersonToggleViewModel)
        await menu.onAppear()
        XCTAssertFalse(menu.shouldShowCardReaderSection)
        mockOnboardingUseCase.refreshIfNecessaryWasCalled = false

        // When
        await withCheckedContinuation { continuation in
            storage.performAndSave({ storage in
                let setting = storage.insertNewObject(ofType: StorageSiteSetting.self)
                setting.update(with: SiteSetting.fake().copy(siteID: self.sampleStoreID,
                                                            settingID: "woocommerce_default_country",
                                                            value: "GB",
                                                            settingGroupKey: SiteSettingGroup.general.rawValue))
            }, completion: { continuation.resume() }, on: .main)
        }
        settings.refresh()
        XCTAssertEqual(SiteAddress(siteSettings: settings.siteSettings).countryCode, .GB)
        await menu.onAppear()

        // Then
        XCTAssertTrue(menu.shouldShowCardReaderSection)
        XCTAssertTrue(mockOnboardingUseCase.refreshIfNecessaryWasCalled)
    }

    func test_country_change_when_settings_arrive_then_does_not_refresh_payment_gateways() async {
        // Given
        let settings = MockSelectedSiteSettings()
        let changes = PassthroughSubject<MockSelectedSiteSettings.SettingsUpdate, Never>()
        settings.mockSettingsStream = changes.eraseToAnyPublisher()
        let toggle = MockInPersonPaymentsCashOnDeliveryToggleRowViewModel()
        let menu = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                                dependencies: .init(cardPresentPaymentsConfiguration: .init(country: .unknown),
                                                                    onboardingUseCase: mockOnboardingUseCase,
                                                                    cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                    wooPaymentsPayoutService: nil,
                                                                    systemStatusService: MockSystemStatusService(),
                                                                    siteSettings: settings),
                                                payInPersonToggleViewModel: toggle)
        let initialized = expectation(description: "Initial country visibility applied")
        let initialSubscription = menu.$shouldShowCardReaderSection.dropFirst().first().sink { _ in initialized.fulfill() }
        defer { initialSubscription.cancel() }
        await fulfillment(of: [initialized], timeout: 5)
        toggle.spyDidCallRefreshState = false

        let recovered = expectation(description: "Country recovery updated visibility")
        var refreshedPaymentGateways = false
        let recoverySubscription = menu.$shouldShowCardReaderSection.first(where: { $0 }).sink { _ in
            refreshedPaymentGateways = toggle.spyDidCallRefreshState
            recovered.fulfill()
        }
        defer { recoverySubscription.cancel() }

        // When
        sendCountry("GB", to: changes)
        await fulfillment(of: [recovered], timeout: 5)

        // Then
        XCTAssertTrue(menu.shouldShowCardReaderSection)
        XCTAssertFalse(refreshedPaymentGateways)
    }

    func test_country_change_when_unsupported_then_clears_onboarding_notice_and_loading() {
        for state in [CardPresentPaymentOnboardingState.pluginSetupNotCompleted(plugin: .wcPay), .loading] {
            // Given
            let changes = PassthroughSubject<MockSelectedSiteSettings.SettingsUpdate, Never>()
            let menu = makeMenuForCountryChanges(state: state, changes: changes)
            XCTAssertEqual(menu.backgroundOnboardingInProgress, state == .loading)
            XCTAssertEqual(menu.cardPresentPaymentsOnboardingNotice != nil, state != .loading)

            // When
            sendCountry("LT", to: changes)

            // Then
            XCTAssertNil(menu.cardPresentPaymentsOnboardingNotice)
            XCTAssertFalse(menu.backgroundOnboardingInProgress)
            XCTAssertTrue(menu.shouldDisableManageCardReaders)
            XCTAssertNil(menu.selectedPaymentGatewayPlugin)
            XCTAssertNil(mockPayInPersonToggleViewModel.selectedPlugin)
        }
    }

    func test_country_change_when_support_returns_then_restores_cached_onboarding_state() {
        // Given
        let changes = PassthroughSubject<MockSelectedSiteSettings.SettingsUpdate, Never>()
        let menu = makeMenuForCountryChanges(state: .completed(plugin: .wcPayPreferred), changes: changes)
        XCTAssertTrue(menu.shouldShowPaymentOptionsSection)
        XCTAssertFalse(menu.shouldDisableManageCardReaders)

        // When
        sendCountry("LT", to: changes)

        // Then
        XCTAssertFalse(menu.shouldShowPaymentOptionsSection)
        XCTAssertFalse(menu.shouldShowManagePaymentGatewaysRow)
        XCTAssertTrue(menu.shouldDisableManageCardReaders)
        XCTAssertNil(menu.selectedPaymentGatewayName)

        // When: the use case keeps its cached state without publishing it again.
        sendCountry("GB", to: changes)

        // Then
        XCTAssertTrue(menu.shouldShowPaymentOptionsSection)
        XCTAssertTrue(menu.shouldShowManagePaymentGatewaysRow)
        XCTAssertFalse(menu.shouldDisableManageCardReaders)
        XCTAssertEqual(menu.selectedPaymentGatewayPlugin, .wcPay)
        XCTAssertEqual(mockPayInPersonToggleViewModel.selectedPlugin, .wcPay)
    }

    private func makeMenuForCountryChanges(
        state: CardPresentPaymentOnboardingState,
        changes: PassthroughSubject<MockSelectedSiteSettings.SettingsUpdate, Never>
    ) -> InPersonPaymentsMenuViewModel {
        let settings = MockSelectedSiteSettings()
        settings.mockSettingsStream = changes.eraseToAnyPublisher()
        let menu = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                                dependencies: .init(cardPresentPaymentsConfiguration: .init(country: .unknown),
                                                                    onboardingUseCase: MockCardPresentPaymentsOnboardingUseCase(initial: state),
                                                                    cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                    wooPaymentsPayoutService: nil,
                                                                    systemStatusService: systemStatusService,
                                                                    siteSettings: settings),
                                                payInPersonToggleViewModel: mockPayInPersonToggleViewModel)
        sendCountry("GB", to: changes)
        return menu
    }

    private func sendCountry(_ country: String, to changes: PassthroughSubject<MockSelectedSiteSettings.SettingsUpdate, Never>) {
        let setting = SiteSetting.fake().copy(siteID: sampleStoreID,
                                              settingID: "woocommerce_default_country",
                                              value: country,
                                              settingGroupKey: "general")
        changes.send((siteID: sampleStoreID, settings: [setting], source: .storageChange))
    }

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
             minimumOperatingSystemVersionForTapToPay: .init(majorVersion: 18, minorVersion: 0, patchVersion: 1))

         let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: configuration,
                                                                       onboardingUseCase: mockOnboardingUseCase,
                                                                       cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                       wooPaymentsPayoutService: mockPayoutService,
                                                                       systemStatusService: systemStatusService)
         sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                             dependencies: dependencies)

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
            supportedReaders: [.tapToPay],
            supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
            minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
            stripeSmallestCurrencyUnitMultiplier: 100,
            contactlessLimitAmount: nil,
            minimumOperatingSystemVersionForTapToPay: .init(majorVersion: 18, minorVersion: 0, patchVersion: 1))

        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(cardPresentPaymentsConfiguration: configuration,
                                                                      onboardingUseCase: mockOnboardingUseCase,
                                                                      cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                                      wooPaymentsPayoutService: mockPayoutService,
                                                                      systemStatusService: systemStatusService)
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: dependencies)

        // When
        await sut.onAppear()

        // Then
        XCTAssertFalse(sut.shouldShowTapToPaySection)
    }
}
