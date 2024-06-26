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
                                            orderService: orderService)
    }

    override func tearDown() {
        cardPresentPaymentService = nil
        itemProvider = nil
        orderService = nil
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

    func test_isSyncingItems_is_true_when_reload_is_invoked_then_toggled_to_false_when_completed() async throws {
        XCTAssertEqual(sut.isSyncingItems, true, "Precondition")

        // Given/When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.isSyncingItems, false)
    }

    func test_isSyncingItems_is_true_when_reload_is_invoked_then_toggled_to_false_when_error() async throws {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true

        let sut = PointOfSaleDashboardViewModel(itemProvider: itemProvider,
                                                cardPresentPaymentService: cardPresentPaymentService,
                                                orderService: orderService)
        XCTAssertEqual(sut.isSyncingItems, true, "Precondition")

        // Given/When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.isSyncingItems, false)
    }

    func test_reload_invokes_providePointOfSaleItems() async {
        // Given/When
        XCTAssertEqual(itemProvider.provideItemsInvocationCount, 0)
        await sut.reload()

        // Then
        XCTAssertEqual(itemProvider.provideItemsInvocationCount, 1)
    }

    func test_removeAllItemsFromCart_removes_all_items_from_cart() {
        // Given
        let numberOfItems = Int.random(in: 1...5)
        for i in 1...numberOfItems {
            let product = POSProduct(itemID: UUID(),
                                     productID: Int64(i),
                                     name: "Choco",
                                     price: "2.00",
                                     formattedPrice: "$2.00",
                                     itemCategories: [],
                                     productImageSource: nil,
                                     productType: .simple)
            sut.addItemToCart(product)
        }
        XCTAssertEqual(sut.itemsInCart.count, numberOfItems)

        // When
        sut.removeAllItemsFromCart()

        // Then
        XCTAssertEqual(sut.itemsInCart.count, 0)
    }
}

private extension PointOfSaleDashboardViewModelTests {
    enum POSError: Error {
        case forcedError
    }

    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []
        var shouldThrowError: Bool = false
        var provideItemsInvocationCount = 0

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            provideItemsInvocationCount += 1
            if shouldThrowError {
                throw POSError.forcedError
            }
            return items
        }

        func simulate(items: [POSItem]) {
            for item in items {
                self.items.append(item)
            }
        }
    }
}
