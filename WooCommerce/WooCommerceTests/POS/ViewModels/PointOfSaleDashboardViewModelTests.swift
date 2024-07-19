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
                                            totalsViewModel: AnyTotalsViewModel(mockTotalsViewModel),
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

    func test_isAddMoreDisabled_is_true_when_order_is_syncing_and_payment_state_is_idle() {
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be true while syncing order and payment state is idle")

        sut.$isAddMoreDisabled
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate order syncing
        let customCartItems = [CartItem(id: UUID(), item: Self.makeItem(), quantity: 1)]
        mockCartViewModel.submitCart(with: customCartItems)
        sut.totalsViewModel.startSyncingOrder(with: customCartItems, allItems: [])

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isAddMoreDisabled_is_true_for_collectPayment_success() {
        // Given
        let mockTotalsViewModel = MockTotalsViewModel()
        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init()),
                                            totalsViewModel: AnyTotalsViewModel(mockTotalsViewModel))
        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be true after successfully collecting payment")

        sut.$isAddMoreDisabled
            .dropFirst(2)
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate payment state change to processingPayment
        mockTotalsViewModel.paymentState = .processingPayment

        // Simulate payment state change to processingPayment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mockTotalsViewModel.paymentState = .cardPaymentSuccessful
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func test_isAddMoreDisabled_is_true_for_processingPayment() {
        // Given
        let mockTotalsViewModel = MockTotalsViewModel()
        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init()),
                                            totalsViewModel: AnyTotalsViewModel(mockTotalsViewModel))

        let expectation = XCTestExpectation(description: "Expect isAddMoreDisabled to be true when paymentState is processingPayment or cardPaymentSuccessful")

        sut.$isAddMoreDisabled
            .dropFirst(2)
            .sink { value in
                XCTAssertTrue(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate payment state change to processingPayment
        mockTotalsViewModel.paymentState = .idle

        // Simulate payment state change to processingPayment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mockTotalsViewModel.paymentState = .processingPayment
        }

        wait(for: [expectation], timeout: 1.0)
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
