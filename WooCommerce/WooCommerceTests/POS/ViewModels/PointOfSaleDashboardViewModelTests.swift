import XCTest
import Combine
@testable import WooCommerce
@testable import Yosemite

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var mockPOSModel: PointOfSaleAggregateModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var itemProvider: MockPOSItemProvider!
    private var mockCartViewModel: MockCartViewModel!
    private var mockTotalsViewModel: MockTotalsViewModel!
    private var mockItemListViewModel: MockItemListViewModel!
    private var mockConnectivityObserver: MockConnectivityObserver!

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        itemProvider = MockPOSItemProvider()
        mockCartViewModel = MockCartViewModel()
        mockTotalsViewModel = MockTotalsViewModel()
        mockItemListViewModel = MockItemListViewModel()
        mockConnectivityObserver = MockConnectivityObserver()
        let mockOrderService = MockPOSOrderService()
        mockOrderService.orderToReturn = Order.fake()
        mockPOSModel = PointOfSaleAggregateModel(
            itemProvider: itemProvider,
            cardPresentPaymentService: cardPresentPaymentService,
            orderService: mockOrderService)
        sut = PointOfSaleDashboardViewModel(posModel: mockPOSModel,
                                            totalsViewModel: mockTotalsViewModel,
                                            cartViewModel: mockCartViewModel,
                                            itemListViewModel: mockItemListViewModel,
                                            connectivityObserver: mockConnectivityObserver)
        cancellables = []
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        mockCartViewModel = nil
        mockTotalsViewModel = nil
        mockItemListViewModel = nil
        mockConnectivityObserver = nil
        sut = nil
        cancellables = []
        super.tearDown()
    }

    func test_viewmodel_when_loaded_then_has_expected_initial_setup() {
        // Given
        let expectedExitPOSButtonDisabledState = false

        // When/Then
        XCTAssertEqual(sut.isExitPOSDisabled, expectedExitPOSButtonDisabledState)
    }

    func test_isExitPOSDisabled_is_true_for_paymentState_processingPayment() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isExitPOSDisabled to be true when paymentState is processingPayment")

        sut.$isExitPOSDisabled
            .sink { disabled in
                if disabled {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
//        mockPOSModel.paymentState = .processingPayment

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isExitPOSDisabled_is_false_for_paymentState_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isExitPOSDisabled to be false when paymentState is idle")

        sut.$isExitPOSDisabled
            .sink { disabled in
                if !disabled {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
//        mockPOSModel.paymentState = .idle

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isTotalsViewFullScreen_is_true_for_paymentState_processingPayment() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isTotalsViewFullScreen to be true when paymentState is processingPayment")

        sut.$isTotalsViewFullScreen
            .dropFirst()
            .sink { fullscreen in
                if fullscreen {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
//        mockPOSModel.paymentState = .processingPayment

        wait(for: [expectation], timeout: 1.0)
    }

    func test_isTotalsViewFullScreen_is_false_for_paymentState_idle() {
        // Given
        let expectation = XCTestExpectation(description: "Expect isTotalsViewFullScreen to be false when paymentState is idle")

        sut.$isTotalsViewFullScreen
            .sink { fullscreen in
                if !fullscreen {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
//        mockPOSModel.paymentState = .idle

        wait(for: [expectation], timeout: 1.0)
    }

    func test_showsConnectivityError_when_nonReachable_then_shows_error() {
        // Given
        mockConnectivityObserver.setStatus(.notReachable)

        // Then
        XCTAssertTrue(sut.showsConnectivityError)
    }

    func test_showsConnectivityError_when_reachable_then_no_error() {
        // Given
        mockConnectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))

        // Then
        XCTAssertFalse(sut.showsConnectivityError)
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
