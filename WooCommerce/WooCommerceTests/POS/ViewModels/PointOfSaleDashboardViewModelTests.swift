import XCTest
import Combine
@testable import struct Yosemite.POSProduct
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import enum Yosemite.Credentials
@testable import protocol Yosemite.POSItemProvider
@testable import protocol Yosemite.POSItem
@testable import protocol Yosemite.POSOrderServiceProtocol

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var itemProvider: MockPOSItemProvider!
    private var orderService: POSOrderServiceProtocol!
    private var totalsViewModel: TotalsViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        itemProvider = MockPOSItemProvider()
        orderService = POSOrderPreviewService()
        totalsViewModel = TotalsViewModel(orderService: orderService,
                                                  cardPresentPaymentService: cardPresentPaymentService,
                                                  currencyFormatter: .init(currencySettings: .init()))
        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init())
                                            , totalsViewModel: totalsViewModel)
        cancellables = []
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        itemProvider = nil
        orderService = nil
        sut = nil
        cancellables = []
        super.tearDown()
    }

    private func setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: TotalsViewModel.PaymentState,
                                                                                   isSyncingOrder: Bool,
                                                                                   expectedValue: Bool) {
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be set correctly")

        // Initialize TotalsViewModel and PointOfSaleDashboardViewModel
        let totalsViewModel = TotalsViewModel(orderService: orderService,
                                              cardPresentPaymentService: cardPresentPaymentService,
                                              currencyFormatter: .init(currencySettings: .init()))
        totalsViewModel.paymentState = paymentState

        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init()),
                                            totalsViewModel: totalsViewModel)

        // Observe changes
        sut.$isAddMoreDisabled
            .dropFirst()
            .sink { value in
                XCTAssertEqual(value, expectedValue)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger state change
        totalsViewModel.isSyncingOrder = isSyncingOrder

        wait(for: [expectation], timeout: 1.0)
    }

    private func setupViewModelWithExpectationsExpectingAddMoreIsDisabled(paymentState: TotalsViewModel.PaymentState, isSyncingOrder: Bool) {
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be set correctly")

        // Initialize TotalsViewModel and PointOfSaleDashboardViewModel
        let totalsViewModel = TotalsViewModel(orderService: orderService,
                                              cardPresentPaymentService: cardPresentPaymentService,
                                              currencyFormatter: .init(currencySettings: .init()))
        totalsViewModel.paymentState = paymentState

        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init()),
                                            totalsViewModel: totalsViewModel)

        // Observe changes
        sut.$isAddMoreDisabled
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger state change
        totalsViewModel.isSyncingOrder = isSyncingOrder

        wait(for: [expectation], timeout: 1.0)
    }

    func test_viewmodel_when_loaded_then_has_expected_initial_setup() {
        // Given
        let expectedCartCollapsedState = true
        let expectedAddMoreButtonDisabledState = false
        let expectedExitPOSButtonDisabledState = false
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building

        // When/Then
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
        XCTAssertEqual(sut.isCartCollapsed, expectedCartCollapsedState)
        XCTAssertEqual(sut.isAddMoreDisabled, expectedAddMoreButtonDisabledState)
        XCTAssertEqual(sut.isExitPOSDisabled, expectedExitPOSButtonDisabledState)
    }

    func test_start_new_transaction() {
        // Given
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building
        let expectedCartEmpty = true
        let expectedPaymentState = TotalsViewModel.PaymentState.acceptingCard
        let expectedCartCollapsedState = true

        // When
        sut.startNewTransaction()

        // Then
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
        XCTAssertEqual(sut.cartViewModel.itemsInCart.isEmpty, expectedCartEmpty)
        XCTAssertEqual(sut.totalsViewModel.paymentState, expectedPaymentState)
        XCTAssertEqual(sut.isCartCollapsed, expectedCartCollapsedState)
        XCTAssertNil(sut.totalsViewModel.order)
    }

    func test_items_added_to_cart() {
        // Given
        let item = Self.makeItem()
        let expectedCartEmpty = false
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building
        let expectedCartCollapsedState = false

        // When
        sut.itemListViewModel.select(item)

        // Then
        XCTAssertEqual(sut.cartViewModel.itemsInCart.isEmpty, expectedCartEmpty)
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
        XCTAssertEqual(sut.isCartCollapsed, expectedCartCollapsedState)
    }

    func test_add_more_is_disabled_for_processing_payment_state() {
        setupViewModelWithExpectationsExpectingAddMoreIsDisabled(paymentState: .processingPayment, isSyncingOrder: true)
        setupViewModelWithExpectationsExpectingAddMoreIsDisabled(paymentState: .processingPayment, isSyncingOrder: false)
    }

    func test_add_more_is_disabled_for_card_payment_successful_state() {
        setupViewModelWithExpectationsExpectingAddMoreIsDisabled(paymentState: .cardPaymentSuccessful, isSyncingOrder: true)
        setupViewModelWithExpectationsExpectingAddMoreIsDisabled(paymentState: .cardPaymentSuccessful, isSyncingOrder: false)
    }

    func test_add_more_disabled_follows_syncing_state_for_idle_state() {
        setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: .idle, isSyncingOrder: true, expectedValue: true)
        setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: .idle, isSyncingOrder: false, expectedValue: false)
    }

    func test_add_more_disabled_follows_syncing_state_for_accepting_card_state() {
        setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: .acceptingCard, isSyncingOrder: true, expectedValue: true)
        setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: .acceptingCard, isSyncingOrder: false, expectedValue: false)
    }

    func test_add_more_disabled_follows_syncing_state_for_preparing_reader_state() {
        setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: .preparingReader, isSyncingOrder: true, expectedValue: true)
        setupViewModelWithExpectationsExpectingAddMoreMatchesSyncingState(paymentState: .preparingReader, isSyncingOrder: false, expectedValue: false)
    }

    // TODO:
    // https://github.com/woocommerce/woocommerce-ios/issues/13210
}

private extension PointOfSaleDashboardViewModelTests {
    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            []
        }
    }

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
