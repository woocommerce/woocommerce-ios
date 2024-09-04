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

        XCTAssertEqual(sut.state, .loading)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .empty)
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

    func test_isHeaderBannerDismissed_when_dismissBanner_is_called_then_returns_true() {
        // Given
        XCTAssertEqual(sut.isHeaderBannerDismissed, false)

        // When
        sut.dismissBanner()

        // Then
        XCTAssertEqual(sut.isHeaderBannerDismissed, true)
    }

    func test_shouldShowHeaderBanner_when_itemListViewModel_is_loading_then_returns_false() {
        // Given/When/Then
        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(sut.shouldShowHeaderBanner, false)
    }

    func test_shouldShowHeaderBanner_when_itemListViewModel_throws_error_then_returns_false() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true
        let sut = ItemListViewModel(itemProvider: itemProvider)
        let expectedError = ItemListViewModel.ErrorModel(title: "Error loading products",
                                                         subtitle: "Give it another go?",
                                                         buttonText: "Retry")

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state, .error(expectedError))
        XCTAssertEqual(sut.shouldShowHeaderBanner, false)
    }

    func test_state_when_itemListViewModel_loaded_normally_then_returns_isLoaded_true() async {
        // Given/When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state.isLoaded, true)
    }

    func test_state_when_itemListViewModel_throws_error_then_returns_isLoaded_false() async {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldThrowError = true
        let sut = ItemListViewModel(itemProvider: itemProvider)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(sut.state.isLoaded, false)
    }

    func test_populatePointOfSaleItems_when_no_items_are_loaded_then_itemsPublisher_emits_no_items() async throws {
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldReturnZeroItems = true
        let sut = ItemListViewModel(itemProvider: itemProvider)

        let expectation = XCTestExpectation(description: "Publisher should emit nothing")
        var receivedItems: [POSItem] = []
        sut.itemsPublisher.sink { items in
            receivedItems = items
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertTrue(sut.state == .empty)
        XCTAssertTrue(receivedItems.isEmpty)
    }

    func test_populatePointOfSaleItems_when_items_are_loaded_then_itemsPublisher_emits_items() async throws {
        // Given
        let items = Self.makeItems()
        let expectation = XCTestExpectation(description: "Publisher should emit populated items")
        var receivedItems: [POSItem] = []
        sut.itemsPublisher.sink { items in
            receivedItems = items
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        await sut.populatePointOfSaleItems()
        guard let firstItem = items.first, let lastItem = items.last else {
            return XCTFail("Expected two items, got \(receivedItems).")
        }

        // Then
        XCTAssertTrue(sut.state == .loaded(receivedItems))
        XCTAssertEqual(receivedItems.first?.productID, firstItem.productID)
        XCTAssertEqual(receivedItems.last?.productID, lastItem.productID)
    }

    func test_populatePointOfSaleItems_when_no_items_are_loaded_then_statePublisher_emits_expected_empty_state() async throws {
        // Given
        XCTAssertEqual(sut.state, .loading, "Initial state")

        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldReturnZeroItems = true
        let sut = ItemListViewModel(itemProvider: itemProvider)
        let expectation = XCTestExpectation(description: "Publisher should emit state changes")

        var receivedStates: [ItemListViewModel.ItemListState] = []
        sut.statePublisher
            .removeDuplicates()
            .sink { state in
                receivedStates.append(state)
                expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(receivedStates, [.loading, .empty])
    }

    func test_populatePointOfSaleItems_when_items_are_loaded_then_statePublisher_emits_expected_loaded_state() async throws {
        // Given
        XCTAssertEqual(sut.state, .loading, "Initial state")
        let expectation = XCTestExpectation(description: "Publisher should emit state changes")
        let items = Self.makeItems()

        var receivedStates: [ItemListViewModel.ItemListState] = []
        sut.statePublisher
            .removeDuplicates()
            .sink { state in
                receivedStates.append(state)
                expectation.fulfill()
        }
        .store(in: &cancellables)

        // When
        await sut.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(receivedStates, [.loading, .loaded(items)])
    }

    func test_simpleProductsInfoButtonTapped_when_tapped_then_showSimpleProductsModal_toggled() {
        XCTAssertFalse(sut.showSimpleProductsModal)

        sut.simpleProductsInfoButtonTapped()

        XCTAssertTrue(sut.showSimpleProductsModal)
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
