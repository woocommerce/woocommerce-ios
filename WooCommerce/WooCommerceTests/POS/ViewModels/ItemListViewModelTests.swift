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

    func test_itemListViewModel_when_populatePointOfSaleItems_is_called_then_items_are_populated() async {
        // Given
        XCTAssertEqual(sut.items.count, 0)
        let expectedItems = Self.makeItems()

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.items.count, expectedItems.count)
    }

    func test_itemListViewModel_when_populatePointOfSaleItems_is_called_multiple_times_then_items_are_not_aggregated() async {
        // Given
        XCTAssertEqual(sut.items.count, 0)
        let expectedItems = Self.makeItems()

        // When
        await sut.populatePointOfSaleItems()
        await sut.populatePointOfSaleItems()
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.items.count, expectedItems.count)
    }

    func test_itemListViewModel_when_reload_is_called_then_items_are_populated() async {
        // Given
        XCTAssertEqual(sut.items.count, 0)
        let expectedItems = Self.makeItems()

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.items.count, expectedItems.count)
    }

    func test_itemListViewModel_when_reload_is_called_multiple_times_then_items_are_not_aggregated() async {
        // Given
        XCTAssertEqual(sut.items.count, 0)
        let expectedItems = Self.makeItems()

        // When
        await sut.reload()
        await sut.reload()
        await sut.reload()

        // Then
        XCTAssertEqual(sut.items.count, expectedItems.count)
    }

    func test_itemListViewModel_when_select_item_then_sends_item_to_publisher() {
        // Given
        let items = Self.makeItems()
        let expectation = XCTestExpectation(description: "Publisher should emit the selected item")

        var receivedItem: POSItem?
        sut.selectedItemPublisher.sink { item in
            receivedItem = item
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        guard let item = items.first else {
            return XCTFail("Expected an item, got none.")
        }
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
        let expectedItems = Self.makeItems()

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .loaded(expectedItems))
    }

    func test_itemListViewModel_when_populatePointOfSaleItems_has_no_items_then_state_is_loaded_empty() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldReturnZeroItems = true
        let sut = ItemListViewModel(itemProvider: itemProvider)
        let expectedResult = ItemListViewModel.EmptyModel(title: "No products",
                                                          subtitle: "Your store doesn't have any products",
                                                          hint: "POS currently only supports simple products",
                                                          buttonText: "Create a simple product")

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .empty(expectedResult))
    }

    func test_itemListViewModel_when_populatePointOfSaleItems_throws_error_then_state_is_error() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true
        let sut = ItemListViewModel(itemProvider: itemProvider)
        let expectedError = ItemListViewModel.ErrorModel(title: "Error loading products",
                                                         subtitle: "Give it another go?",
                                                         buttonText: "Retry")

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .error(expectedError))
    }

    func test_itemListViewModel_when_reload_then_state_is_loaded_with_expected_items() async {
        // Given
        XCTAssertEqual(sut.state, .loading)
        let expectedItems = Self.makeItems()

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.state, .loaded(expectedItems))
    }

    func test_itemListViewModel_when_reload_throws_error_then_state_is_error() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true
        let sut = ItemListViewModel(itemProvider: itemProvider)
        let expectedError = ItemListViewModel.ErrorModel(title: "Error loading products",
                                                         subtitle: "Give it another go?",
                                                         buttonText: "Retry")

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(sut.state, .error(expectedError))
    }

}

private extension ItemListViewModelTests {
    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []
        var shouldThrowError = false
        var shouldReturnZeroItems = false

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            if shouldThrowError {
                throw NSError(domain: "Some error", code: 0)
            }
            if shouldReturnZeroItems {
                return []
            }
            return makeItems()
        }
    }

    static func makeItems() -> [POSItem] {
        let fakeUUID1 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E84E") ?? UUID()
        let fakeUUID2 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E84A") ?? UUID()

        let product1 = POSProduct(itemID: fakeUUID1,
                                  productID: 0,
                                  name: "Choco",
                                  price: "2",
                                  formattedPrice: "$2.00",
                                  itemCategories: [],
                                  productImageSource: nil,
                                  productType: .simple)

        let product2 = POSProduct(itemID: fakeUUID2,
                                  productID: 1,
                                  name: "Vanilla",
                                  price: "3",
                                  formattedPrice: "$3.00",
                                  itemCategories: [],
                                  productImageSource: nil,
                                  productType: .simple)
        return [product1, product2]
    }
}
