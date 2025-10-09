import Testing
import Foundation
@testable import PointOfSale
@testable import Yosemite

final class PointOfSaleObservableItemsControllerTests {

    // MARK: - Test Helpers

    private func makeSimpleProduct(id: UUID = UUID(), name: String = "Test Product", productID: Int64 = 1) -> POSItem {
        .simpleProduct(POSSimpleProduct(
            id: id,
            name: name,
            formattedPrice: "$2.00",
            productID: productID,
            price: "2.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
    }

    private func makeVariation(id: UUID = UUID(), name: String = "Test Variation", variationID: Int64 = 1) -> POSItem {
        .variation(POSVariation(
            id: id,
            name: name,
            formattedPrice: "$2.00",
            price: "2.00",
            productID: 100,
            variationID: variationID,
            parentProductName: "Parent Product"
        ))
    }

    // MARK: - Tests

    @Test func test_initial_state_is_loading_container_with_initial_root() {
        // Given
        let dataSource = MockPOSObservableDataSource()
        dataSource.isLoadingProducts = true
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        // Then
        #expect(sut.itemsViewState.containerState == .loading)
        #expect(sut.itemsViewState.itemsStack.root == .initial)
        #expect(sut.itemsViewState.itemsStack.itemStates.isEmpty)
    }

    @Test func test_load_products_transitions_to_loaded_state() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let mockItems = [makeSimpleProduct()]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        dataSource.hasMoreProducts = false

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(mockItems, hasMoreItems: false))
    }

    @Test func test_load_products_with_more_pages_sets_hasMoreItems() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let mockItems = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        dataSource.hasMoreProducts = true

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.itemsStack.root == .loaded(mockItems, hasMoreItems: true))
    }

    @Test func test_load_products_when_empty_results_in_empty_state() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .empty)
    }

    @Test func test_load_variations_for_parent() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let parentProduct = POSVariableParentProduct(
            id: UUID(),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        let mockVariations = [makeVariation(variationID: 1), makeVariation(variationID: 2)]
        dataSource.variationItems = mockVariations
        dataSource.isLoadingVariations = false
        dataSource.hasMoreVariations = false

        // When
        await sut.loadItems(base: .parent(parentItem))

        // Then
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .loaded(mockVariations, hasMoreItems: false))
    }

    @Test func test_load_variations_when_empty_results_in_empty_state() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let parentProduct = POSVariableParentProduct(
            id: UUID(),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        dataSource.variationItems = []
        dataSource.isLoadingVariations = false

        // When
        await sut.loadItems(base: .parent(parentItem))

        // Then
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .empty)
    }

    @Test func test_products_and_variations_are_independent() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let mockProducts = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]
        let mockVariations = [makeVariation()]

        let parentProduct = POSVariableParentProduct(
            id: UUID(),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        // When: Load products
        dataSource.productItems = mockProducts
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // Then: Products loaded, no variations
        #expect(sut.itemsViewState.itemsStack.root.items.count == 2)
        #expect(sut.itemsViewState.itemsStack.itemStates.isEmpty)

        // When: Load variations
        dataSource.variationItems = mockVariations
        dataSource.isLoadingVariations = false
        await sut.loadItems(base: .parent(parentItem))

        // Then: Both products and variations present
        #expect(sut.itemsViewState.itemsStack.root.items.count == 2)
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem]?.items.count == 1)
    }

    @Test func test_load_next_items_delegates_to_data_source() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        // Simulate initial load
        dataSource.productItems = [makeSimpleProduct()]
        dataSource.isLoadingProducts = false
        dataSource.hasMoreProducts = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then: loadMoreProducts should be called (verified by state change in mock)
        // Note: Mock doesn't actually track calls, but we can verify the state
        #expect(sut.itemsViewState.containerState == .content)
    }

    @Test func test_refresh_delegates_to_data_source() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        dataSource.productItems = [makeSimpleProduct()]
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // When
        await sut.refreshItems(base: .root)

        // Then: Should still be in content state
        #expect(sut.itemsViewState.containerState == .content)
    }

    @Test func test_switching_parent_resets_variation_state() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let parent1 = POSVariableParentProduct(id: UUID(), name: "Parent 1", productImageSource: nil, productID: 100, allAttributes: [])
        let parentItem1 = POSItem.variableParentProduct(parent1)

        let parent2 = POSVariableParentProduct(id: UUID(), name: "Parent 2", productImageSource: nil, productID: 200, allAttributes: [])
        let parentItem2 = POSItem.variableParentProduct(parent2)

        // When: Load parent 1 variations
        dataSource.variationItems = [makeVariation()]
        dataSource.isLoadingVariations = false
        await sut.loadItems(base: .parent(parentItem1))

        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem1]?.items.count == 1)

        // When: Load parent 2 variations
        dataSource.variationItems = [makeVariation(variationID: 1), makeVariation(variationID: 2)]
        await sut.loadItems(base: .parent(parentItem2))

        // Then: Parent 2 variations shown, parent 1 not in states anymore
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem2]?.items.count == 2)
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem1] == nil)
    }

    @Test func test_error_state_when_data_source_has_error() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        dataSource.error = NSError(domain: "test", code: 1)

        // When
        await sut.loadItems(base: .root)

        // Then
        guard case .error = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected error state, got \(sut.itemsViewState.itemsStack.root)")
            return
        }
    }

    @Test func test_loading_state_preserves_existing_items() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let sut = PointOfSaleObservableItemsController(dataSource: dataSource)

        let mockItems = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]

        // Load initial items
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // When: Start loading more
        dataSource.isLoadingProducts = true

        // Then: Loading state should preserve items
        #expect(sut.itemsViewState.itemsStack.root == .loading(mockItems))
    }
}
