import XCTest
@testable import struct Yosemite.POSProduct
@testable import WooCommerce
@testable import class Yosemite.PointOfSaleOrderService
@testable import enum Networking.Credentials

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: CardPresentPaymentPreviewService!

    override func setUp() {
        super.setUp()
        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        let credentials = Credentials(authToken: "token")
        let orderService = PointOfSaleOrderService(siteID: siteID,
                                                   credentials: credentials)
        cardPresentPaymentService = CardPresentPaymentPreviewService()
        sut = PointOfSaleDashboardViewModel(items: [],
                                            cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                            orderService: orderService)
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        sut = nil
        super.tearDown()
    }

    func test_cart_is_empty_initially() {
        // Given/Then
        XCTAssertTrue(sut.itemsInCart.isEmpty)
    }

    func test_cart_is_collapsed_when_empty_then_not_collapsed_when_has_items() {
        XCTAssertTrue(sut.itemsInCart.isEmpty, "Precondition")
        XCTAssertTrue(sut.isCartCollapsed, "Precondition")

        // Given
        let product = POSProduct(itemID: UUID(),
                                 productID: 0,
                                 name: "Choco",
                                 price: "2.00",
                                 formattedPrice: "$2.00",
                                 productImageSource: nil)

        // When
        sut.addItemToCart(product)

        // Then
        XCTAssertFalse(sut.itemsInCart.isEmpty)
        XCTAssertFalse(sut.isCartCollapsed)
    }
}
