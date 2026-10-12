import Testing
@testable import WooCommerce

struct ProductListPageOrderTests {
    @Test
    func test_ordered_when_a_page_sorts_before_earlier_pages_locally_then_keeps_it_after_them() {
        // Given
        var order = ProductListPageOrder()
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: 1)

        // When
        order.record(identities(makeProducts([1, 3, 4, 2])), syncingPageNumber: 2)
        let ordered = order.ordered(makeProducts([1, 3, 4, 2]))

        // Then
        #expect(ordered.map(\.productID) == [1, 2, 3, 4])
    }

    @Test
    func test_ordered_when_a_product_is_added_without_a_page_sync_then_keeps_it_after_its_local_predecessor() {
        // Given
        var order = ProductListPageOrder()
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: 1)
        order.record(identities(makeProducts([1, 3, 2])), syncingPageNumber: 2)

        // When: a new product sorts between products from page 2 and page 1
        order.record(identities(makeProducts([1, 3, 5, 2])), syncingPageNumber: nil)
        let ordered = order.ordered(makeProducts([1, 3, 5, 2]))

        // Then
        #expect(ordered.map(\.productID) == [1, 2, 3, 5])
    }

    @Test
    func test_ordered_when_a_product_is_renamed_then_moves_it_to_the_page_of_its_local_predecessor() {
        // Given
        var order = ProductListPageOrder()
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: 1)
        order.record(identities(makeProducts([1, 2, 3])), syncingPageNumber: 2)

        // When: product 3 is renamed so that it sorts first
        let products = makeProducts([3, 1, 2], names: [3: "Renamed"])
        order.record(identities(products), syncingPageNumber: nil)

        // Then
        #expect(order.ordered(products).map(\.productID) == [3, 1, 2])
    }

    @Test
    func test_ordered_when_a_removed_product_is_added_again_then_keeps_it_after_its_local_predecessor() {
        // Given
        var order = ProductListPageOrder()
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: 1)
        order.record(identities(makeProducts([1, 3, 2])), syncingPageNumber: 2)
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: nil)

        // When
        order.record(identities(makeProducts([1, 3, 2])), syncingPageNumber: nil)

        // Then
        #expect(order.ordered(makeProducts([1, 3, 2])).map(\.productID) == [1, 3, 2])
    }

    @Test
    func test_ordered_when_a_product_is_renamed_while_a_page_syncs_then_keeps_it_in_the_page_of_its_local_predecessor() {
        // Given
        var order = ProductListPageOrder()
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: 1)

        // When: product 2 is renamed while page 2 syncs, then page 2 arrives
        order.record(identities(makeProducts([1, 2], names: [2: "Renamed"])), syncingPageNumber: 2)
        let products = makeProducts([1, 3, 2], names: [2: "Renamed"])
        order.record(identities(products), syncingPageNumber: 2)

        // Then
        #expect(order.ordered(products).map(\.productID) == [1, 2, 3])
    }

    @Test
    func test_ordered_when_reset_then_uses_the_local_order() {
        // Given
        var order = ProductListPageOrder()
        order.record(identities(makeProducts([1, 2])), syncingPageNumber: 1)
        order.record(identities(makeProducts([1, 3, 2])), syncingPageNumber: 2)

        // When
        order.reset()

        // Then
        #expect(order.ordered(makeProducts([1, 3, 2])).map(\.productID) == [1, 3, 2])
    }
}

private extension ProductListPageOrderTests {
    func identities(_ products: [ProductListItem]) -> [(productID: Int64, name: String)] {
        products.map { ($0.productID, $0.name) }
    }

    func makeProducts(_ productIDs: [Int64], names: [Int64: String] = [:]) -> [ProductListItem] {
        productIDs.map { productID in
            ProductListItem(siteID: 123,
                            productID: productID,
                            name: names[productID] ?? "Product \(productID)",
                            productTypeKey: "simple",
                            statusKey: "publish",
                            sku: nil,
                            price: "",
                            manageStock: false,
                            stockQuantity: nil,
                            stockStatusKey: "instock",
                            imageURL: nil,
                            variations: [],
                            bundleStockStatus: nil,
                            bundleStockQuantity: nil)
        }
    }
}
