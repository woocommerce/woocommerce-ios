import XCTest
@testable import struct Yosemite.POSProduct
@testable import WooCommerce

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: CardPresentPaymentPreviewService!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = CardPresentPaymentPreviewService()
        sut = PointOfSaleDashboardViewModel(items: [],
                                            cardPresentPaymentService: cardPresentPaymentService)
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
                                 productImageSource: nil)

        // When
        sut.addItemToCart(product)

        // Then
        XCTAssertFalse(sut.itemsInCart.isEmpty)
        XCTAssertFalse(sut.isCartCollapsed)
    }
}
