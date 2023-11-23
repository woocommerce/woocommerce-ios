import XCTest
import TestKit
@testable import Yosemite
@testable import WooCommerce

/// Temporarily removed pending a rewrite for the new InPersonPaymentsMenuViewModel #11168
class InPersonPaymentsMenuViewModelTests: XCTestCase {

    private var sut: InPersonPaymentsMenuViewModel!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var mockDepositService: MockWooPaymentsDepositService!

    private let sampleStoreID: Int64 = 12345

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        mockDepositService = MockWooPaymentsDepositService()
        let mockOnboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .completed(plugin: .wcPayOnly))
        sut = InPersonPaymentsMenuViewModel(siteID: sampleStoreID,
                                            dependencies: .init(
                                                cardPresentPaymentsConfiguration: .init(country: .US),
                                                onboardingUseCase: mockOnboardingUseCase,
                                                cardReaderSupportDeterminer: MockCardReaderSupportDeterminer(),
                                                wooPaymentsDepositService: mockDepositService,
                                                analytics: analytics))
    }

    func test_onAppear_when_no_deposit_summaries_are_returned_depositSummaryShown_is_not_tracked() async {
        // Given
        mockDepositService.onFetchDepositsOverviewThenReturn = []

        // When
        await sut.onAppear()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(where: { eventName in
            eventName == WooAnalyticsStat.paymentsMenuDepositSummaryShown.rawValue
        }))
    }

    func test_onAppear_when_deposit_summaries_are_returned_depositSummaryShown_is_tracked() async throws {
        // Given
        mockDepositService.onFetchDepositsOverviewThenReturn = [.fake().copy(currency: .USD), .fake().copy(currency: .GBP)]

        // When
        await sut.onAppear()

        // Then
        let eventIndex = try? XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.paymentsMenuDepositSummaryShown.rawValue))

        XCTAssertNotNil(eventIndex)

        guard let eventIndex else {
            return XCTFail("Expected event not found")
        }

        guard let properties = try XCTUnwrap(analyticsProvider.receivedProperties[safe: eventIndex]) as? [String: Int] else {
            return XCTFail("Expected properties not tracked")
        }
        assertEqual(properties["number_of_currencies"], 2)
    }

    func test_onAppear_when_deposit_service_gets_an_error_depositSummaryError_is_tracked() async {
        // Given
        mockDepositService.onFetchDepositsOverviewShouldThrow = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "description"))

        // When
        await sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryError.rawValue))
    }

//     private var stores: MockStoresManager!

//     private var analyticsProvider: MockAnalyticsProvider!
//     private var analytics: Analytics!

//     private var sut: LegacyInPersonPaymentsMenuViewModel!

//     private let sampleStoreID: Int64 = 12345

//     private var configuration: CardPresentPaymentsConfiguration!

//     override func setUp() {
//         stores = MockStoresManager(sessionManager: .makeForTesting())
//         stores.sessionManager.setStoreId(sampleStoreID)

//         analyticsProvider = MockAnalyticsProvider()
//         analytics = WooAnalytics(analyticsProvider: analyticsProvider)

//         let dependencies = LegacyInPersonPaymentsMenuViewModel.Dependencies(stores: stores,
//                                                                       analytics: analytics)

//         configuration = CardPresentPaymentsConfiguration(country: .US)

//         sut = LegacyInPersonPaymentsMenuViewModel(dependencies: dependencies,
//                                             cardPresentPaymentsConfiguration: configuration)
//     }

//     func test_viewDidLoad_synchronizes_payment_gateways() throws {
//         // Given
//         assertEmpty(stores.receivedActions)

//         // When
//         sut.viewDidLoad()

//         // Then
//         let action = try XCTUnwrap(stores.receivedActions.first(where: { $0 is PaymentGatewayAction }) as? PaymentGatewayAction)
//         switch action {
//         case .synchronizePaymentGateways(let siteID, _):
//             assertEqual(siteID, sampleStoreID)
//         default:
//             XCTFail("viewDidLoad failed to dispatch .synchronizePaymentGateways action")
//         }
//     }

//     func test_orderCardReaderPressed_tracks_paymentsMenuOrderCardReaderTapped() {
//         // Given

//         // When
//         sut.orderCardReaderPressed()

//         // Then
//         XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "payments_hub_order_card_reader_tapped" }))
//     }

//     func test_orderCardReaderPressed_presents_card_reader_purchase_web_view() throws {
//         // Given
//         XCTAssertNil(sut.showWebView)

//         // When
//         sut.orderCardReaderPressed()

//         // Then
//         let cardReaderPurchaseURL = try XCTUnwrap(sut.showWebView?.initialURL)
//         assertEqual("https", cardReaderPurchaseURL.scheme)
//         assertEqual("woo.com", cardReaderPurchaseURL.host)
//         assertEqual("/products/hardware/US", cardReaderPurchaseURL.path)
//         let query = try XCTUnwrap(cardReaderPurchaseURL.query)
//         XCTAssert(query.contains("utm_medium=woo_ios"))
//         XCTAssert(query.contains("utm_campaign=payments_menu_item"))
//         XCTAssert(query.contains("utm_source=payments_menu"))
//     }

//     func test_isEligibleForTapToPayOnIPhone_false_when_built_in_reader_isnt_in_configuration() {
//         // Given
//         let dependencies = LegacyInPersonPaymentsMenuViewModel.Dependencies(stores: stores,
//                                                                       analytics: analytics)

//         let configuration = CardPresentPaymentsConfiguration(
//             countryCode: .IN,
//             paymentMethods: [.cardPresent],
//             currencies: [.INR],
//             paymentGateways: [WCPayAccount.gatewayID],
//             supportedReaders: [.wisepad3],
//             supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
//             minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
//             stripeSmallestCurrencyUnitMultiplier: 100,
//             contactlessLimitAmount: nil,
//             minimumOperatingSystemVersionForTapToPay: .init(majorVersion: 16, minorVersion: 0, patchVersion: 0))

//         sut = LegacyInPersonPaymentsMenuViewModel(dependencies: dependencies,
//                                             cardPresentPaymentsConfiguration: configuration)

//         // When
//         sut.viewDidLoad()
//         let eligiblity = sut.isEligibleForTapToPayOnIPhone

//         // Then
//         XCTAssertFalse(eligiblity)
//     }

//     func test_isEligibleForTapToPayOnIPhone_true_when_built_in_reader_is_in_configuration() {
//         // Given
//         let dependencies = LegacyInPersonPaymentsMenuViewModel.Dependencies(stores: stores,
//                                                                       analytics: analytics)

//         let configuration = CardPresentPaymentsConfiguration(
//             countryCode: .IN,
//             paymentMethods: [.cardPresent],
//             currencies: [.INR],
//             paymentGateways: [WCPayAccount.gatewayID],
//             supportedReaders: [.appleBuiltIn],
//             supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
//             minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
//             stripeSmallestCurrencyUnitMultiplier: 100,
//             contactlessLimitAmount: nil,
//             minimumOperatingSystemVersionForTapToPay: .init(majorVersion: 16, minorVersion: 0, patchVersion: 0))

//         sut = LegacyInPersonPaymentsMenuViewModel(dependencies: dependencies,
//                                             cardPresentPaymentsConfiguration: configuration)

//         waitFor { promise in
//             self.stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
//                 switch action {
//                 case .checkDeviceSupport(_, _, _, _, let completion):
//                     completion(true)
//                     promise(())
//                 default:
//                     XCTFail("Unexpected CardPresentPaymentAction recieved")
//                 }
//             }

//             // When
//             self.sut.viewDidLoad()
//         }

//         let eligiblity = sut.isEligibleForTapToPayOnIPhone

//         // Then
//         XCTAssertTrue(eligiblity)
//     }
}
