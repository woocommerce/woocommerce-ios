import XCTest
import Combine
@testable import WooCommerce
@testable import Yosemite

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var itemProvider: MockPOSItemProvider!
    private var mockCartViewModel: MockCartViewModel!
    private var mockTotalsViewModel: MockTotalsViewModel!
    private var mockItemListViewModel: MockItemListViewModel!
    private var orderService: POSOrderServiceProtocol!

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        itemProvider = MockPOSItemProvider()
        mockCartViewModel = MockCartViewModel()
        mockTotalsViewModel = MockTotalsViewModel()
        mockItemListViewModel = MockItemListViewModel()
        orderService = POSOrderPreviewService()
        sut = PointOfSaleDashboardViewModel(cardPresentPaymentService: cardPresentPaymentService,
                                            itemProvider: itemProvider,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: ServiceLocator.currencySettings),
                                            totalsViewModel: mockTotalsViewModel,
                                            cartViewModel: mockCartViewModel,
                                            itemListViewModel: mockItemListViewModel)
        cancellables = []
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        mockCartViewModel = nil
        mockTotalsViewModel = nil
        mockItemListViewModel = nil
        orderService = nil
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
        let itemsAdded = false
        let expectedPaymentState = TotalsViewModel.PaymentState.acceptingCard

        // When
        sut.startNewTransaction()

        // Then
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
        XCTAssertEqual(mockCartViewModel.addItemToCartCalled, itemsAdded)
        XCTAssertEqual(sut.totalsViewModel.paymentState, expectedPaymentState)
        XCTAssertNil(sut.totalsViewModel.order)
    }

    func test_items_added_to_cart() {
        // Given
        let item = Self.makeItem()
        let itemsAdded = true
        let expectedOrderStage = PointOfSaleDashboardViewModel.OrderStage.building

        // When
        mockCartViewModel.addItemToCart(item)

        // Then
        XCTAssertEqual(mockCartViewModel.addItemToCartCalled, itemsAdded)
        XCTAssertEqual(sut.orderStage, expectedOrderStage)
    }

    func test_isAddMoreDisabled_is_true_when_order_is_syncing_and_paymentState_is_idle() {
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

    func test_isAddMoreDisabled_is_true_for_paymentState_processingPayment() {
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

    func test_isExitPOSDisabled_is_true_for_paymentState_processingPayment() {
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

    func test_isExitPOSDisabled_is_false_for_paymentState_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isExitPOSDisabled to be false when paymentState is idle")

        sut.$isExitPOSDisabled
            .sink { value in
                XCTAssertFalse(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .idle

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isTotalsViewFullScreen_is_true_for_paymentState_processingPayment() {
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

    func test_isTotalsViewFullScreen_is_false_for_paymentState_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isTotalsViewFullScreen to be false when paymentState is idle")

        sut.$isTotalsViewFullScreen
            .sink { value in
                XCTAssertFalse(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockTotalsViewModel.paymentState = .idle

        wait(for: [expectation], timeout: 1.0)
    }

    func test_observeCartSubmission_updates_orderStage() {
        // Given
        let expectation = XCTestExpectation(description: "Expect orderStage to be .finalizing and isSyncingOrder to be true")
        let customCartItems = [CartItem(id: UUID(), item: Self.makeItem(), quantity: 1)]

        // Attach sink to observe changes to orderStage
        var orderStageValue: PointOfSaleDashboardViewModel.OrderStage?
        sut.$orderStage
            .sink { orderStage in
                orderStageValue = orderStage
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockCartViewModel.submitCart(with: customCartItems)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(orderStageValue, .finalizing)
    }

    func test_observeCartSubmission_starts_syncing_order() {
        // Given
        let expectation = XCTestExpectation(description: "Expect orderStage to be .finalizing and isSyncingOrder to be true")
        let customCartItems = [CartItem(id: UUID(), item: Self.makeItem(), quantity: 1)]
        var receivedIsSyncingOrder: Bool = false

        // Attach sink to observe changes to isSyncingOrder
        mockTotalsViewModel.isSyncingOrderPublisher
            .sink { isSyncingOrder in
                receivedIsSyncingOrder = isSyncingOrder
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockCartViewModel.submitCart(with: customCartItems)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedIsSyncingOrder)
    }

    func test_observeCartAddMoreAction_updates_orderStage_to_building() {
        // Given
        let expectation = XCTestExpectation(description: "Expect orderStage to be .building when adding more to the cart")

        var receivedOrderStage: PointOfSaleDashboardViewModel.OrderStage?
        // Attach sink to observe changes to orderStage
        sut.$orderStage
            // Ignore the initial value of orderStage to ensure that the test only reacts to changes in the orderStage after the subscription has started.
            .dropFirst()
            .sink { orderStage in
                receivedOrderStage = orderStage
                XCTAssertEqual(receivedOrderStage, .building)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockCartViewModel.addMoreToCart()

        wait(for: [expectation], timeout: 1.0)
    }

    func test_observeCartItemsToCheckIfCartIsEmpty_updates_orderStage_to_building() {
        // Given
        let expectation = XCTestExpectation(description: "Expect orderStage to be .building when cart becomes empty")
        var receivedOrderStage: PointOfSaleDashboardViewModel.OrderStage?

        // Attach sink to observe changes to orderStage
        sut.$orderStage
            .dropFirst() // Ignore the initial value. Avoids immediately fulfilling the expectation upon subscribing.
            .sink { orderStage in
                receivedOrderStage = orderStage
                if orderStage == .building {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockCartViewModel.itemsInCart = [] // Trigger the empty cart condition

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedOrderStage, .building)
    }

    func test_isInitialLoading_when_item_list_loading_and_empty_then_true() {
        // Given
        mockItemListViewModel.items = []
        mockItemListViewModel.state = .loading

        // Then
        XCTAssertTrue(sut.isInitialLoading)
    }

    func test_isInitialLoading_when_item_list_empty_then_false() {
        // Given
        mockItemListViewModel.items = []
        mockItemListViewModel.state = .empty(.init(title: "", subtitle: "", hint: "", buttonText: ""))

        // Then
        XCTAssertFalse(sut.isInitialLoading)
    }

    func test_isInitialLoading_when_item_list_loaded_and_then_false() {
        // Given
        let items = [Self.makeItem()]
        mockItemListViewModel.items = items
        mockItemListViewModel.state = .loaded(items)

        // Then
        XCTAssertFalse(sut.isInitialLoading)
    }

    func test_showModal_sets_activeModal() {
        // Given
        let expectation = XCTestExpectation(description: "Expect activeModal to be set")
        let modalType: PointOfSaleDashboardViewModel.ActiveModal = .simpleProducts // Use ActiveModal instead of ModalType

        var receivedActiveModal: PointOfSaleDashboardViewModel.ActiveModal? // Change the type here
        // Attach sink to observe changes to activeModal
        sut.$activeModal
            .dropFirst()
            .sink { activeModal in
                receivedActiveModal = activeModal
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.showModal(modalType)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedActiveModal, modalType)
    }

    func test_hideModal_clears_activeModal() {
        // Given
        let expectation = XCTestExpectation(description: "Expect activeModal to be cleared")
        let modalType: PointOfSaleDashboardViewModel.ActiveModal = .simpleProducts // Use ActiveModal instead of ModalType

        var receivedActiveModal: PointOfSaleDashboardViewModel.ActiveModal? // Change the type here
        // Attach sink to observe changes to activeModal
        sut.$activeModal
            .dropFirst(2) // Drop initial and first update from showModal
            .sink { activeModal in
                receivedActiveModal = activeModal
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.showModal(modalType)
        sut.hideModal()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedActiveModal)
    }

    func test_shouldShowModal_whenModalIsActive() {
        // Given
        sut.showModal(.simpleProducts)

        // When
        let result = sut.shouldShowModal(.simpleProducts)

        // Then
        XCTAssertTrue(result, "Expected shouldShowModal to return true when the modal is active")
    }

    func test_showModal_updates_activeModal() {
        XCTAssertNil(sut.activeModal, "activeModal should be nil initially")

        sut.showModal(.simpleProducts)

        XCTAssertEqual(sut.activeModal, .simpleProducts, "activeModal should be set to .simpleProducts")
    }

    func test_hideModal_resets_activeModal_to_nil() {
        sut.activeModal = .simpleProducts
        XCTAssertEqual(sut.activeModal, .simpleProducts, "activeModal should be set to .simpleProducts")

        sut.hideModal()

        XCTAssertNil(sut.activeModal, "activeModal should be nil after hiding the modal")
    }

    func test_ActiveModal_conformsToIdentifiable() {
        let modal = PointOfSaleDashboardViewModel.ActiveModal.simpleProducts
        XCTAssertEqual(modal.id, "simpleProducts", "ActiveModal id should be 'simpleProducts'")
    }
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
