import XCTest
import Combine
@testable import WooCommerce
@testable import protocol Yosemite.POSItemProvider
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class ItemSelectorViewModelTests: XCTestCase {
    private var itemProvider: POSItemProvider!
    private var itemSelector: ItemSelectorViewModel!

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        itemProvider = MockPOSItemProvider()
        itemSelector = ItemSelectorViewModel(itemProvider: itemProvider)
    }

    override func tearDown() {
        itemProvider = nil
        itemSelector = nil
        super.tearDown()
    }

    func test_isSyncingItems_is_true_when_populatePointOfSaleItems_is_invoked_then_switches_to_false_when_completed() async {
        XCTAssertEqual(itemSelector.isSyncingItems, true, "Precondition")

        // Given/When
        await itemSelector.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(itemSelector.isSyncingItems, false)
    }

    func test_isSyncingItems_is_true_when_reload_is_invoked_then_switches_to_false_when_completed() async {
        XCTAssertEqual(itemSelector.isSyncingItems, true, "Precondition")

        // Given/When
        await itemSelector.reload()

        // Then
        XCTAssertEqual(itemSelector.isSyncingItems, false)
    }

    func test_itemSelector_when_select_item_then_sends_item_to_publisher() {
        // Given
        let item = Self.makeItem()
        let expectation = XCTestExpectation(description: "Publisher should emit the selected item")

        var receivedItem: POSItem?
        itemSelector.selectedItemPublisher.sink { item in
            receivedItem = item
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        itemSelector.select(item)

        // Then
        XCTAssertEqual(receivedItem?.productID, item.productID)
    }

    func test_itemSelector_when_initilized_then_state_is_loading() {
        // Given/When/Then
        XCTAssertEqual(itemSelector.state, .loading)
    }

    func test_itemSelector_when_populatePointOfSaleItems_then_state_is_loaded() async {
        // Given
        XCTAssertEqual(itemSelector.state, .loading)

        // When
        await itemSelector.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(itemSelector.state, .loaded)
    }

    func test_itemSelector_when_reload_then_state_is_loaded() async {
        // Given
        XCTAssertEqual(itemSelector.state, .loading)
        
        // When
        await itemSelector.reload()

        // Then
        XCTAssertEqual(itemSelector.state, .loaded)
    }

}

private extension ItemSelectorViewModelTests {
    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            let item = makeItem()
            return [item]
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
