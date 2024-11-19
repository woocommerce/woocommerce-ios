import XCTest
import Combine
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import protocol Yosemite.POSOrderServiceProtocol
@testable import struct Yosemite.Order
@testable import struct Yosemite.POSProduct
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.OrderItem

final class TotalsViewModelTests: XCTestCase {

    private var sut: TotalsViewModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var orderService: MockPOSOrderService!
    private var posModel: PointOfSaleAggregateModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        orderService = MockPOSOrderService()
        posModel = PointOfSaleAggregateModel(
            itemProvider: MockPOSItemProvider(),
            cardPresentPaymentService: cardPresentPaymentService,
            orderService: orderService)
        sut = TotalsViewModel(posModel: posModel,
                              cardPresentPaymentService: cardPresentPaymentService)
        cancellables = Set()
    }

    // MARK: Onboarding

    func test_cardPresentPaymentOnboardingViewModel_is_non_nil_when_onboarding_is_required() {
        // Given
        let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(fixedState: .pluginNotActivated(plugin: .stripe))
        cardPresentPaymentService.paymentEvent = .idle
        XCTAssertNil(sut.cardPresentPaymentOnboardingViewModel)

        // When
        cardPresentPaymentService.paymentEvent = .showOnboarding(onboardingViewModel: onboardingViewModel, onCancel: {})

        // Then
        XCTAssertEqual(sut.cardPresentPaymentOnboardingViewModel?.state, .pluginNotActivated(plugin: .stripe))
    }

    // MARK: Analytics

    func test_paymentsOnboardingDismissed_event_is_tracked_with_state_when_cancelOnboarding_is_invoked() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = TotalsViewModel(posModel: posModel,
                                  cardPresentPaymentService: cardPresentPaymentService,
                                  analytics: analytics)
        let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(fixedState: .noConnectionError)
        cardPresentPaymentService.paymentEvent = .showOnboarding(onboardingViewModel: onboardingViewModel, onCancel: {})

        // When
        sut.cancelOnboarding()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "pos_payments_onboarding_dismissed" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first(where: { $0.keys.contains("onboarding_state") }))
        XCTAssertEqual(eventProperties["onboarding_state"] as? String, "no_connection_error")
    }

    func test_pointOfSalePaymentsOnboardingShown_event_is_tracked_when_trackOnboardingShown_is_invoked() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = TotalsViewModel(posModel: posModel,
                                  cardPresentPaymentService: cardPresentPaymentService,
                                  analytics: analytics)

        // When
        sut.trackOnboardingShown()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "pos_payments_onboarding_shown" }))
    }
}

private extension TotalsViewModelTests {
    static func makeItem() -> POSItem {
        return POSProduct(itemID: UUID(),
                          productID: 0,
                          name: "",
                          price: "",
                          formattedPrice: "",
                          itemCategories: [],
                          productImageSource: nil,
                          productType: .simple)
    }
}
