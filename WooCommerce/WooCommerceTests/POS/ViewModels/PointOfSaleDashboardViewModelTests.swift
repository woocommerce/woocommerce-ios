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
    private var mockConnectivityObserver: MockConnectivityObserver!

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        itemProvider = MockPOSItemProvider()
        mockCartViewModel = MockCartViewModel()
        mockConnectivityObserver = MockConnectivityObserver()
        let mockOrderService = MockPOSOrderService()
        mockOrderService.orderToReturn = Order.fake()
        mockPOSModel = PointOfSaleAggregateModel(
            itemProvider: itemProvider,
            cardPresentPaymentService: cardPresentPaymentService,
            orderService: mockOrderService)
        sut = PointOfSaleDashboardViewModel(posModel: mockPOSModel,
                                            cartViewModel: mockCartViewModel,
                                            connectivityObserver: mockConnectivityObserver)
        cancellables = []
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        mockCartViewModel = nil
        mockConnectivityObserver = nil
        sut = nil
        cancellables = []
        super.tearDown()
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
