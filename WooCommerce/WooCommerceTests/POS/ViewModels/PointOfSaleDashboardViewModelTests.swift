import XCTest
@testable import struct Yosemite.POSProduct
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import enum Yosemite.Credentials
@testable import protocol Yosemite.POSItemProvider
@testable import protocol Yosemite.POSItem
@testable import protocol Yosemite.POSOrderServiceProtocol

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: CardPresentPaymentPreviewService!
    private var itemProvider: MockPOSItemProvider!
    private var orderService: POSOrderServiceProtocol!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = CardPresentPaymentPreviewService()
        itemProvider = MockPOSItemProvider()
        orderService = POSOrderPreviewService()
        sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: orderService,
                                            currencyFormatter: .init(currencySettings: .init()))
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        itemProvider = nil
        orderService = nil
        sut = nil
        super.tearDown()
    }

    func test_plain_setup() {
        XCTAssertEqual(sut.orderStage, .building)
        XCTAssertEqual(sut.isCartCollapsed, true)
        XCTAssertEqual(sut.isAddMoreDisabled, false)
        XCTAssertEqual(sut.isExitPOSDisabled, false)
    }

    func test_startNewTransaction() {
        sut.startNewTransaction()

        XCTAssertEqual(sut.orderStage, .building)
        XCTAssertEqual(sut.cartViewModel.itemsInCart.isEmpty, true)
        XCTAssertEqual(sut.totalsViewModel.paymentState, .acceptingCard)
        XCTAssertNil(sut.totalsViewModel.order)
    }

    func test_items_added_to_cart() {
        let item = Self.makeItem()

        sut.itemSelectorViewModel.select(item)

        XCTAssertEqual(sut.cartViewModel.itemsInCart.isEmpty, false)
        XCTAssertEqual(sut.isCartCollapsed, false)
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
