import XCTest
import Combine
@testable import WooCommerce
@testable import Yosemite

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var itemProvider: MockPOSItemProvider!
    private var orderService: POSOrderServiceProtocol!
    private var mockCartViewModel: MockCartViewModel!
    private var mockTotalsViewModel: MockTotalsViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        itemProvider = MockPOSItemProvider()
        orderService = POSOrderPreviewService()
        mockCartViewModel = MockCartViewModel(orderStage: Just(PointOfSaleDashboardViewModel.OrderStage.building).eraseToAnyPublisher())
        mockTotalsViewModel = MockTotalsViewModel()
        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init()),
                                            totalsViewModel: mockTotalsViewModel,
                                            cartViewModel: mockCartViewModel.cartViewModel)
        cancellables = []
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        itemProvider = nil
        orderService = nil
        mockCartViewModel = nil
        mockTotalsViewModel = nil
        sut = nil
        cancellables = []
        super.tearDown()
    }

    func test_viewmodel_when_loaded_then_has_expected_initial_setup() {
        // Given
        let expectedAddMoreButtonDisabledState = false
        let expectedExitPOSButtonDisabledState = false
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building

        // When/Then
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
        XCTAssertEqual(sut.isAddMoreDisabled, expectedAddMoreButtonDisabledState)
        XCTAssertEqual(sut.isExitPOSDisabled, expectedExitPOSButtonDisabledState)
    }

    func test_start_new_transaction() {
        // Given
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building
        let expectedCartEmpty = true
        let expectedPaymentState = TotalsViewModel.PaymentState.acceptingCard

        // When
        sut.startNewTransaction()

        // Then
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
        XCTAssertEqual(sut.cartViewModel.itemsInCart.isEmpty, expectedCartEmpty)
        XCTAssertEqual(sut.totalsViewModel.paymentState, expectedPaymentState)
        XCTAssertNil(sut.totalsViewModel.order)
    }

    func test_items_added_to_cart() {
        // Given
        let item = Self.makeItem()
        let expectedCartEmpty = false
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building

        // When
        sut.itemListViewModel.select(item)

        // Then
        XCTAssertEqual(sut.cartViewModel.itemsInCart.isEmpty, expectedCartEmpty)
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
    }

    func test_isAddMoreDisabled_is_true_when_order_is_syncing_and_payment_state_is_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be true while syncing order and payment state is idle")

        sut.$isAddMoreDisabled
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        let customCartItems = [CartItem(id: UUID(), item: Self.makeItem(), quantity: 1)]
        sut.totalsViewModel.startSyncingOrder(with: customCartItems, allItems: [])

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isAddMoreDisabled_is_true_for_collectPayment_success() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be true after successfully collecting payment")

        sut.$isAddMoreDisabled
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .cardPaymentSuccessful

        wait(for: [expectation], timeout: 2.0)
    }

    func test_isAddMoreDisabled_is_true_for_processingPayment() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be true when paymentState is processingPayment or cardPaymentSuccessful")

        sut.$isAddMoreDisabled
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .processingPayment

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isExitPOSDisabled_is_true_for_processingPayment() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isExitPOSDisabled to be true when paymentState is processingPayment")

        sut.$isExitPOSDisabled
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .processingPayment

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isExitPOSDisabled_is_false_for_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isExitPOSDisabled to be false when paymentState is idle")

        sut.$isExitPOSDisabled
            .dropFirst()
            .sink { value in
                XCTAssertFalse(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .idle

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isTotalsViewFullScreen_is_true_for_processingPayment() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isTotalsViewFullScreen to be true when paymentState is processingPayment")

        sut.$isTotalsViewFullScreen
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .processingPayment

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isTotalsViewFullScreen_is_false_for_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isTotalsViewFullScreen to be true when paymentState is processingPayment")

        sut.$isTotalsViewFullScreen
            .dropFirst()
            .sink { value in
                XCTAssertFalse(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .idle

        wait(for: [expectation], timeout: 1.0)
    }

    func test_observeCartSubmission_updates_orderStage_and_starts_syncing_order() {
        // Given
        let expectation = XCTestExpectation(description: "Expect orderStage to be .finalizing and isSyncingOrder to be true")
        let customCartItems = [CartItem(id: UUID(), item: Self.makeItem(), quantity: 1)]
        var receivedIsSyncingOrder: Bool = false

        // Observe the isSyncingOrderPublisher to verify its value
        mockTotalsViewModel.isSyncingOrderPublisher
            .sink { isSyncingOrder in
                receivedIsSyncingOrder = isSyncingOrder
                if isSyncingOrder {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Attach sink to observe changes to orderStage
        var orderStageValue: PointOfSaleDashboardViewModel.OrderStage?
        sut.$orderStage
            .sink { orderStage in
                orderStageValue = orderStage
            }
            .store(in: &cancellables)

        // When
        mockCartViewModel.submitCart(with: customCartItems)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(orderStageValue, .finalizing)
        XCTAssertTrue(receivedIsSyncingOrder)
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
