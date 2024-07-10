import XCTest
import Combine
@testable import WooCommerce
@testable import protocol Yosemite.POSItemProvider
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class ItemListViewModelTests: XCTestCase {
    private var itemProvider: POSItemProvider!
    private var sut: ItemListViewModel!

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        itemProvider = MockPOSItemProvider()
        sut = ItemListViewModel(itemProvider: itemProvider)
    }

    override func tearDown() {
        itemProvider = nil
        sut = nil
        super.tearDown()
    }

    func test_itemListViewModel_when_select_item_then_sends_item_to_publisher() {
        // Given
        let item = Self.makeItem()
        let expectation = XCTestExpectation(description: "Publisher should emit the selected item")

        var receivedItem: POSItem?
        sut.selectedItemPublisher.sink { item in
            receivedItem = item
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        sut.select(item)

        // Then
        XCTAssertEqual(receivedItem?.productID, item.productID)
    }

    func test_itemListViewModel_when_initilized_then_state_is_loading() {
        // Given/When/Then
        XCTAssertEqual(sut.state, .loading)
    }

    func test_itemListViewModel_when_populatePointOfSaleItems_then_state_is_loaded() async {
        // Given
        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .loaded)
    }

    func test_itemListViewModel_when_populatePointOfSaleItems_throws_error_then_state_is_error() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true
        let sut = ItemListViewModel(itemProvider: itemProvider)

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .error)
    }

    func test_itemListViewModel_when_reload_then_state_is_loaded() async {
        // Given
        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.state, .loaded)
    }

    func test_itemListViewModel_when_reload_throws_error_then_state_is_error() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true
        let sut = ItemListViewModel(itemProvider: itemProvider)

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.state, .error)
    }

}

private extension ItemListViewModelTests {
    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []
        var shouldThrowError = false

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            if shouldThrowError {
                throw NSError(domain: "Some error", code: 0)
            }
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
