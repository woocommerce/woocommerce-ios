import XCTest
@testable import struct Yosemite.POSProduct
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import enum Yosemite.Credentials

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var cardPresentPaymentService: CardPresentPaymentPreviewService!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = CardPresentPaymentPreviewService()
        sut = PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                            cardPresentPaymentService: cardPresentPaymentService,
                                            orderService: POSOrderPreviewService())
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
                                 itemCategories: [],
                                 productImageSource: nil,
                                 productType: .simple)

        // When
        sut.addItemToCart(product)

        // Then
        XCTAssertFalse(sut.itemsInCart.isEmpty)
        XCTAssertFalse(sut.isCartCollapsed)
    }

    func test_isSyncingItems_is_true_when_populatePointOfSaleItems_is_invoked_then_switches_to_false_when_completed() async {
        XCTAssertEqual(sut.isSyncingItems, true, "Precondition")

        // Given/When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.isSyncingItems, false)
    }
}
