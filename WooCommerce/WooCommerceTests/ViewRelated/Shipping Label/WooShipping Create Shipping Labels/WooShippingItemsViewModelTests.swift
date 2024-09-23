import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WooShippingItemsViewModelTests: XCTestCase {

    private var currencySettings: CurrencySettings!
    private var shippingSettingsService: MockShippingSettingsService!

    override func setUp() {
        currencySettings = CurrencySettings()
        shippingSettingsService = MockShippingSettingsService()
    }

    func test_inits_with_expected_values_from_order_items() throws {
        // Given
        let dimensions = ProductDimensions(length: "20", width: "35", height: "5")
        let products = [Product.fake().copy(productID: 1)]
        let productVariations = [ProductVariation.fake().copy(productVariationID: 2, dimensions: dimensions)]
        let orderItems = [OrderItem.fake().copy(name: "Shirt",
                                                variationID: 2,
                                                quantity: 1,
                                                price: 10,
                                                attributes: [OrderItemAttribute.fake().copy(value: "Red")]),
                          OrderItem.fake().copy(productID: 1, quantity: 1, price: 2.5)]
        let dataSource = MockDataSource(orderItems: orderItems, products: products, productVariations: productVariations)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        // Section header labels have expected values
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("0 oz • $12.50", viewModel.itemsDetailLabel)

        // Section rows have expected values
        assertEqual(2, viewModel.itemRows.count)
        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("Shirt", firstItem.name)
        assertEqual("1", firstItem.quantityLabel)
        assertEqual("$10.00", firstItem.priceLabel)
        assertEqual("20 x 35 x 5 in • Red", firstItem.detailsLabel)
    }

    func test_populates_item_data_from_products_and_variations() {
        // Given
        let dimensions = ProductDimensions(length: "20", width: "35", height: "5")
        let image = ProductImage.fake().copy(src: "http://woocommerce.com/image.jpg")
        let product = Product.fake().copy(productID: 1, weight: "5", dimensions: dimensions, images: [image])
        let variation = ProductVariation.fake().copy(productID: 2, productVariationID: 12, image: image, weight: "3", dimensions: dimensions)
        let orderItems = [OrderItem.fake().copy(productID: product.productID, quantity: 1),
                          OrderItem.fake().copy(productID: variation.productID,
                                                variationID: variation.productVariationID,
                                                quantity: 1,
                                                attributes: [OrderItemAttribute.fake().copy(value: "Red")])]
        let dataSource = MockDataSource(orderItems: orderItems, products: [product], productVariations: [variation])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("8 oz • $0.00", viewModel.itemsDetailLabel)

        let productRow = viewModel.itemRows[0]
        XCTAssertNotNil(productRow.imageUrl)
        assertEqual("5 oz", productRow.weightLabel)
        assertEqual("20 x 35 x 5 in", productRow.detailsLabel)

        let variationRow = viewModel.itemRows[1]
        XCTAssertNotNil(variationRow.imageUrl)
        assertEqual("3 oz", variationRow.weightLabel)
        assertEqual("20 x 35 x 5 in • Red", variationRow.detailsLabel)
    }

    func test_total_items_count_handles_items_with_quantity_greater_than_one() {
        // Given
        let products = [Product.fake().copy(productID: 1), Product.fake().copy(productID: 2)]
        let orderItems = [OrderItem.fake().copy(productID: 1, quantity: 2), OrderItem.fake().copy(productID: 2, quantity: 1)]
        let dataSource = MockDataSource(orderItems: orderItems, products: products)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        assertEqual("3 items", viewModel.itemsCountLabel)
    }

    func test_total_items_details_handles_items_with_quantity_greater_than_one() {
        // Given
        let dimensions = ProductDimensions(length: "20", width: "35", height: "5")
        let product = Product.fake().copy(productID: 1, weight: "5", dimensions: dimensions)
        let variation = ProductVariation.fake().copy(productID: 2, productVariationID: 12, weight: "3", dimensions: dimensions)
        let orderItems = [OrderItem.fake().copy(productID: product.productID, quantity: 2, price: 10),
                          OrderItem.fake().copy(productID: variation.productID, variationID: variation.productVariationID, quantity: 1, price: 2.5)]
        let dataSource = MockDataSource(orderItems: orderItems, products: [product], productVariations: [variation])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("13 oz • $22.50", viewModel.itemsDetailLabel)
    }

    func test_item_row_details_label_handles_items_with_multiple_attributes() throws {
        // Given
        let dimensions = ProductDimensions(length: "20", width: "35", height: "5")
        let productVariation = ProductVariation.fake().copy(productVariationID: 1, dimensions: dimensions)
        let orderItems = [OrderItem.fake().copy(variationID: productVariation.productVariationID,
                                                attributes: [OrderItemAttribute.fake().copy(value: "Red"),
                                                             OrderItemAttribute.fake().copy(value: "Small")])]
        let dataSource = MockDataSource(orderItems: orderItems, productVariations: [productVariation])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings, shippingSettingsService: shippingSettingsService)

        // Then
        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("20 x 35 x 5 in • Red, Small", firstItem.detailsLabel)
    }

    func test_item_rows_handle_items_with_quantity_greater_than_one() throws {
        // Given
        let product = Product.fake().copy(productID: 1, weight: "3")
        let orderItem = OrderItem.fake().copy(productID: product.productID, quantity: 2, price: 10)
        let dataSource = MockDataSource(orderItems: [orderItem], products: [product])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings, shippingSettingsService: shippingSettingsService)

        // Then
        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("6 oz", firstItem.weightLabel)
        assertEqual("$20.00", firstItem.priceLabel)
    }

}

private final class MockDataSource: WooShippingItemsDataSource {
    var items: [ShippingLabelPackageItem]

    var orderItems: [OrderItem]

    var products: [Product]

    var productVariations: [ProductVariation]

    init(orderItems: [OrderItem] = [],
         products: [Product] = [],
         productVariations: [ProductVariation] = []) {
        self.orderItems = orderItems
        self.products = products
        self.productVariations = productVariations
        self.items = orderItems.compactMap { ShippingLabelPackageItem(orderItem: $0, products: products, productVariations: productVariations)}
    }
}
