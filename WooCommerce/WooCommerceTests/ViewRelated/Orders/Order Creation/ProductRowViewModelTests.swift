import Experiments
import XCTest
import Yosemite
import Fakes
import WooFoundation
@testable import WooCommerce

final class ProductRowViewModelTests: XCTestCase {
    func test_viewModel_is_created_with_correct_initial_values_from_product() {
        // Given
        let rowID = Int64(0)
        let imageURLString = "https://woocommerce.com/woo.jpg"
        let product = Product.fake().copy(productID: 12,
                                          name: "Test Product",
                                          images: [ProductImage.fake().copy(src: imageURLString)])

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, product.productID)
        XCTAssertEqual(viewModel.name, product.name)
        XCTAssertEqual(viewModel.imageURL, URL(string: imageURLString))
        XCTAssertEqual(viewModel.quantity, 1)
        XCTAssertEqual(viewModel.numberOfVariations, 0)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: "variable", variations: [0, 1, 2])

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        XCTAssertEqual(viewModel.numberOfVariations, 3)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_product_variation() {
        // Given
        let rowID = Int64(0)
        let imageURLString = "https://woocommerce.com/woo.jpg"
        let name = "Blue - Any Size"
        let productVariation = ProductVariation.fake().copy(productVariationID: 12,
                                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")],
                                                            image: ProductImage.fake().copy(src: imageURLString))

        // When
        let viewModel = ProductRowViewModel(id: rowID, productVariation: productVariation, name: name, displayMode: .stock)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, productVariation.productVariationID)
        XCTAssertEqual(viewModel.name, name)
        XCTAssertEqual(viewModel.imageURL, URL(string: imageURLString))
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_view_model_creates_expected_label_for_product_with_managed_stock() {
        // Given
        let stockQuantity: Decimal = 7
        let product = Product.fake().copy(manageStock: true, stockQuantity: stockQuantity, stockStatusKey: "instock")

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        let expectedStockLabel = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_unmanaged_stock() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "instock")

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedStockLabel = NSLocalizedString("In stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_out_of_stock_product() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "outofstock")

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedStockLabel = NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_price() {
        // Given
        let price = "2.50"
        let product = Product.fake().copy(price: price)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, currencyFormatter: currencyFormatter)

        // Then
        let expectedPriceLabel = "2.50"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_price_and_discount() {
        // Given
        let price = "2.50"
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, discount: discount, currencyFormatter: currencyFormatter)

        // Then
        let expectedPriceLabel = "2.50" + " - " + (currencyFormatter.formatAmount(discount) ?? "")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_no_price() {
        // Given
        let price = ""
        let product = Product.fake().copy(price: price)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, currencyFormatter: currencyFormatter)

        // Then
        let expectedPriceLabel = "$0.00"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_product_details_label_for_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: "variable", stockStatusKey: "instock", variations: [0, 1])

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedProductDetailsLabel = "In stock • 2 variations"
        XCTAssertEqual(viewModel.productDetailsLabel, expectedProductDetailsLabel)
    }

    func test_view_model_creates_expected_label_for_variation_with_attributes_display_mode() {
        // Given
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")], stockStatus: .inStock)
        let attributes = [VariationAttributeViewModel(name: "Color", value: "Blue"), VariationAttributeViewModel(name: "Size")]

        // When
        let viewModel = ProductRowViewModel(productVariation: variation, name: "", displayMode: .attributes(attributes))

        // Then
        let expectedAttributesText = "Blue, Any Size"
        let unexpectedStockText = "In stock"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedAttributesText),
                      "Expected label to contain \"\(expectedAttributesText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
        XCTAssertFalse(viewModel.productDetailsLabel.contains(unexpectedStockText))
    }

    func test_view_model_creates_expected_label_for_variation_with_stock_display_mode() {
        // Given
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")], stockStatus: .inStock)

        // When
        let viewModel = ProductRowViewModel(productVariation: variation, name: "", displayMode: .stock)

        // Then
        let expectedStockText = "In stock"
        let unexpectedAttributesText = "Blue"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockText),
                      "Expected label to contain \"\(expectedStockText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
        XCTAssertFalse(viewModel.productDetailsLabel.contains(unexpectedAttributesText))
    }

    func test_sku_label_is_formatted_correctly_for_product_with_sku() {
        // Given
        let sku = "123456"
        let product = Product.fake().copy(sku: sku)

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let format = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        let expectedSKULabel = String.localizedStringWithFormat(format, sku)
        XCTAssertEqual(viewModel.skuLabel, expectedSKULabel)
    }

    func test_sku_label_is_empty_for_product_without_sku() {
        // Given
        let sku = ""
        let product = Product.fake().copy(sku: sku)

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedSKULabel = ""
        XCTAssertEqual(viewModel.skuLabel, expectedSKULabel)
    }

    func test_secondaryProductDetailsLabel_is_formatted_correctly_for_non_configurable_product_with_sku() {
        // Given
        let sku = "123456"
        let product = Product.fake().copy(sku: sku)

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let format = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        let expectedSKULabel = String.localizedStringWithFormat(format, sku)
        XCTAssertEqual(viewModel.secondaryProductDetailsLabel, expectedSKULabel)
    }

    func test_secondaryProductDetailsLabel_is_empty_for_non_configurable_product_without_sku() {
        // Given
        let sku = ""
        let product = Product.fake().copy(sku: sku)

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedSKULabel = ""
        XCTAssertEqual(viewModel.secondaryProductDetailsLabel, expectedSKULabel)
    }

    func test_secondaryProductDetailsLabel_contains_product_type_and_formatted_correctly_for_configurable_bundle_product_with_sku() {
        // Given
        let sku = "123456"
        let product = Product.fake().copy(productTypeKey: ProductType.bundle.rawValue, sku: sku, bundledItems: [.fake()])
        let featureFlagService = MockFeatureFlagService(productBundlesInOrderForm: true)

        // When
        let viewModel = ProductRowViewModel(product: product, featureFlagService: featureFlagService, configure: {})

        // Then
        let format = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        let expectedSKULabel = String.localizedStringWithFormat(format, sku)
        XCTAssertTrue(viewModel.secondaryProductDetailsLabel.contains(ProductType.bundle.description))
        XCTAssertTrue(viewModel.secondaryProductDetailsLabel.contains(expectedSKULabel))
    }

    func test_secondaryProductDetailsLabel_is_product_type_for_configurable_bundle_product_without_sku() {
        // Given
        let sku = ""
        let product = Product.fake().copy(productTypeKey: ProductType.bundle.rawValue, sku: sku, bundledItems: [.fake()])
        let featureFlagService = MockFeatureFlagService(productBundlesInOrderForm: true)

        // When
        let viewModel = ProductRowViewModel(product: product, featureFlagService: featureFlagService, configure: {})

        // Then
        XCTAssertEqual(viewModel.secondaryProductDetailsLabel, ProductType.bundle.description)
    }

    func test_productAccessibilityLabel_is_created_with_expected_details_from_product() {
        // Given
        let product = Product.fake().copy(name: "Test Product", sku: "123456", price: "10", stockStatusKey: "instock", variations: [1, 2])
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, currencyFormatter: currencyFormatter)

        // Then
        let expectedLabel = "Test Product. In stock. $10.00. 2 variations. SKU: 123456"
        XCTAssertEqual(viewModel.productAccessibilityLabel, expectedLabel)
    }

    func test_product_stock_status_used_for_product_bundles_when_feature_flag_disabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", stockStatusKey: "instock", bundleStockStatus: .insufficientStock)

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService(productBundles: false))

        // Then
        let expectedStockText = ProductStockStatus.inStock.description
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockText),
                      "Expected label to contain \"\(expectedStockText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_bundle_stock_status_used_for_product_bundles_when_insufficient_stock_and_feature_flag_enabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", stockStatusKey: "instock", bundleStockStatus: .insufficientStock)

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService())

        // Then
        let expectedStockText = ProductStockStatus.insufficientStock.description
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockText),
                      "Expected label to contain \"\(expectedStockText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_product_stock_status_used_for_product_bundles_when_backordered_and_feature_flag_enabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", stockStatusKey: "onbackorder", bundleStockStatus: .inStock)

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService())

        // Then
        let expectedStockText = ProductStockStatus.onBackOrder.description
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockText),
                      "Expected label to contain \"\(expectedStockText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_product_stock_quantity_used_for_product_bundles_when_feature_flag_disabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", manageStock: true, stockQuantity: 5, stockStatusKey: "instock", bundleStockQuantity: 1)

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService(productBundles: false))

        // Then
        let localizedStockQuantity = NumberFormatter.localizedString(from: 5 as NSDecimalNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        let expectedStockLabel = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_bundle_stock_quantity_used_for_product_bundles_when_feature_flag_enabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", manageStock: false, stockQuantity: 5, stockStatusKey: "instock", bundleStockQuantity: 1)

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService())

        // Then
        let localizedStockQuantity = NumberFormatter.localizedString(from: 1 as NSDecimalNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        let expectedStockLabel = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    // MARK: - `isConfigurable`

    func test_isConfigurable_is_false_for_bundle_product_when_feature_flag_is_disabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle")

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService(productBundlesInOrderForm: false))

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_is_false_for_bundle_product_with_empty_bundle_items() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle")

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService(productBundlesInOrderForm: true))

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_is_true_for_bundle_product_with_bundle_items_and_configure_closure() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", bundledItems: [.fake()])

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService(productBundlesInOrderForm: true),
                                            configure: {})

        // Then
        XCTAssertTrue(viewModel.isConfigurable)
    }

    func test_isConfigurable_is_false_for_bundle_product_with_bundle_items_when_configure_closure_is_nil() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", bundledItems: [.fake()])

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            featureFlagService: createFeatureFlagService(productBundlesInOrderForm: true),
                                            configure: nil)

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_is_false_for_non_bundle_product() {
        let nonBundleProductTypes: [ProductType] = [.simple, .grouped, .affiliate, .variable, .subscription, .variableSubscription, .composite]

        nonBundleProductTypes.forEach { nonBundleProductType in
            // Given
            let product = Product.fake().copy(productTypeKey: nonBundleProductType.rawValue)

            // When
            let viewModel = ProductRowViewModel(product: product,
                                                featureFlagService: createFeatureFlagService(productBundlesInOrderForm: true),
                                                configure: {})

            // Then
            XCTAssertFalse(viewModel.isConfigurable)
        }
    }
}

private extension ProductRowViewModelTests {
    func createFeatureFlagService(productBundles: Bool = true, productBundlesInOrderForm: Bool = false) -> FeatureFlagService {
        MockFeatureFlagService(productBundles: productBundles, productBundlesInOrderForm: productBundlesInOrderForm)
    }
}
