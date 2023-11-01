import Experiments
import XCTest
import Yosemite
import Fakes
import WooFoundation
@testable import WooCommerce

final class ProductRowViewModelTests: XCTestCase {
    var analytics: MockAnalyticsProvider!

    override func setUp() {
        super.setUp()
        analytics = MockAnalyticsProvider()
    }

    func test_viewModel_is_created_with_correct_initial_values_from_product() {
        // Given
        let rowID = Int64(0)
        let imageURLString = "https://woo.com/woo.jpg"
        let product = Product.fake().copy(productID: 12,
                                          name: "Test Product",
                                          images: [ProductImage.fake().copy(src: imageURLString)])

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, canChangeQuantity: false)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, product.productID)
        XCTAssertEqual(viewModel.name, product.name)
        XCTAssertEqual(viewModel.imageURL, URL(string: imageURLString))
        XCTAssertFalse(viewModel.canChangeQuantity)
        XCTAssertEqual(viewModel.quantity, 1)
        XCTAssertEqual(viewModel.numberOfVariations, 0)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: "variable", variations: [0, 1, 2])

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        XCTAssertEqual(viewModel.numberOfVariations, 3)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_product_variation() {
        // Given
        let rowID = Int64(0)
        let imageURLString = "https://woo.com/woo.jpg"
        let name = "Blue - Any Size"
        let productVariation = ProductVariation.fake().copy(productVariationID: 12,
                                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")],
                                                            image: ProductImage.fake().copy(src: imageURLString))

        // When
        let viewModel = ProductRowViewModel(id: rowID, productVariation: productVariation, name: name, canChangeQuantity: false, displayMode: .stock)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, productVariation.productVariationID)
        XCTAssertEqual(viewModel.name, name)
        XCTAssertEqual(viewModel.imageURL, URL(string: imageURLString))
        XCTAssertFalse(viewModel.canChangeQuantity)
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_view_model_creates_expected_label_for_product_with_managed_stock() {
        // Given
        let stockQuantity: Decimal = 7
        let product = Product.fake().copy(manageStock: true, stockQuantity: stockQuantity, stockStatusKey: "instock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

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
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedStockLabel = NSLocalizedString("In stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_out_of_stock_product() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "outofstock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

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
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)

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
        let viewModel = ProductRowViewModel(product: product, discount: discount, canChangeQuantity: false, currencyFormatter: currencyFormatter)

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
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)

        // Then
        let expectedPriceLabel = "$0.00"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_updates_price_label_when_quantity_changes() {
        // Given
        let product = Product.fake().copy(price: "2.50")
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)
        viewModel.incrementQuantity()

        // Then
        let expectedPriceLabel = "$5.00"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_product_details_label_for_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: "variable", stockStatusKey: "instock", variations: [0, 1])

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedProductDetailsLabel = "In stock • 2 variations"
        XCTAssertEqual(viewModel.productDetailsLabel, expectedProductDetailsLabel)
    }

    func test_view_model_creates_expected_label_for_variation_with_attributes_display_mode() {
        // Given
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")], stockStatus: .inStock)
        let attributes = [VariationAttributeViewModel(name: "Color", value: "Blue"), VariationAttributeViewModel(name: "Size")]

        // When
        let viewModel = ProductRowViewModel(productVariation: variation, name: "", canChangeQuantity: false, displayMode: .attributes(attributes))

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
        let viewModel = ProductRowViewModel(productVariation: variation, name: "", canChangeQuantity: false, displayMode: .stock)

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
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

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
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedSKULabel = ""
        XCTAssertEqual(viewModel.skuLabel, expectedSKULabel)
    }

    func test_increment_and_decrement_quantity_have_step_value_of_one() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)

        // When & Then
        viewModel.incrementQuantity()
        XCTAssertEqual(viewModel.quantity, 2)

        // When & Then
        viewModel.decrementQuantity()
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_quantity_has_minimum_value_of_one() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)
        XCTAssertEqual(viewModel.quantity, 1)

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_cannot_decrement_quantity_below_zero() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product, quantity: 0, canChangeQuantity: true)
        XCTAssertEqual(viewModel.quantity, 0)

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 0)
        XCTAssertTrue(viewModel.shouldDisableQuantityDecrementer, "Quantity decrementer is not disabled")
    }

    func test_decrement_quantity_at_minimum_quantity_removes_product() {
        // Given
        let product = Product.fake()
        var productRemoved = false
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true, removeProductIntent: { productRemoved = true })

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertTrue(productRemoved)
    }

    func test_cannot_decrement_quantity_below_minimumQuantity() {
        // Given
        let viewModel = ProductRowViewModel(productOrVariationID: 1,
                                            name: "",
                                            sku: nil,
                                            price: nil,
                                            stockStatusKey: "",
                                            stockQuantity: nil,
                                            manageStock: false,
                                            quantity: 3,
                                            minimumQuantity: 3,
                                            maximumQuantity: nil,
                                            canChangeQuantity: true,
                                            imageURL: nil,
                                            hasParentProduct: false,
                                            isConfigurable: false)
        XCTAssertEqual(viewModel.quantity, 3)

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 3)
    }

    func test_cannot_increment_quantity_beyond_maximumQuantity() {
        // Given
        let viewModel = ProductRowViewModel(productOrVariationID: 1,
                                            name: "",
                                            sku: nil,
                                            price: nil,
                                            stockStatusKey: "",
                                            stockQuantity: nil,
                                            manageStock: false,
                                            quantity: 6,
                                            minimumQuantity: 4,
                                            maximumQuantity: 6,
                                            canChangeQuantity: true,
                                            imageURL: nil,
                                            hasParentProduct: false,
                                            isConfigurable: false)
        XCTAssertEqual(viewModel.quantity, 6)

        // When
        viewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 6)
    }

    func test_productRow_when_add_discount_button_is_tapped_then_orderProductDiscountAddButtonTapped_is_tracked() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product,
                                            canChangeQuantity: true,
                                            analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackAddDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountAddButtonTapped.rawValue)
    }

    func test_productRow_when_edit_discount_button_is_tapped_then_orderProductDiscountEditButtonTapped_is_tracked() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product,
                                            canChangeQuantity: true,
                                            analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackEditDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountEditButtonTapped.rawValue)
    }

    func test_productAccessibilityLabel_is_created_with_expected_details_from_product() {
        // Given
        let product = Product.fake().copy(name: "Test Product", sku: "123456", price: "10", stockStatusKey: "instock", variations: [1, 2])
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)

        // Then
        let expectedLabel = "Test Product. In stock. $10.00. 2 variations. SKU: 123456"
        XCTAssertEqual(viewModel.productAccessibilityLabel, expectedLabel)
    }

    func test_product_stock_status_used_for_product_bundles_when_feature_flag_disabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", stockStatusKey: "instock", bundleStockStatus: .insufficientStock)

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            canChangeQuantity: false,
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
                                            canChangeQuantity: false,
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
                                            canChangeQuantity: false,
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
                                            canChangeQuantity: false,
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
                                            canChangeQuantity: false,
                                            featureFlagService: createFeatureFlagService())

        // Then
        let localizedStockQuantity = NumberFormatter.localizedString(from: 1 as NSDecimalNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        let expectedStockLabel = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_when_product_row_discount_is_nil_then_viewModel_hasDiscount_is_false() {
        let price = "2.50"
        let product = Product.fake().copy(price: price)

        let viewModel = ProductRowViewModel(product: product, discount: nil, quantity: 1, canChangeQuantity: true)

        XCTAssertFalse(viewModel.hasDiscount)
    }

    func test_when_product_row_discount_is_not_nil_then_viewModel_hasDiscount() {
        let price = "2.50"
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        let viewModel = ProductRowViewModel(product: product, discount: discount, quantity: 1, canChangeQuantity: true)

        XCTAssertTrue(viewModel.hasDiscount)
    }

    func test_product_row_priceQuantityLine_returns_properly_formatted_priceQuantityLine() {
        // Given
        let price = "10.71"
        let quantity: Decimal = 8
        let product = Product.fake().copy(price: price)

        // When
        let viewModel = ProductRowViewModel(product: product, quantity: quantity, canChangeQuantity: true)

        // Then
        assertEqual("8 × $10.71", viewModel.priceQuantityLine)
    }

    func test_totalPriceAfterDiscountLabel_when_product_row_has_one_item_and_discount_then_returns_properly_formatted_price_after_discount() {
        let price = "2.50"
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        let viewModel = ProductRowViewModel(product: product, discount: discount, quantity: 1, canChangeQuantity: true)

        assertEqual("$2.00", viewModel.totalPriceAfterDiscountLabel)
    }

    func test_totalPriceAfterDiscountLabel_when_product_row_has_multiple_item_and_discount_then_returns_properly_formatted_price_after_discount() {
        let price = "2.50"
        let quantity: Decimal = 10
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        let viewModel = ProductRowViewModel(product: product,
                                            discount: discount,
                                            quantity: quantity,
                                            canChangeQuantity: true)

        assertEqual("$24.50", viewModel.totalPriceAfterDiscountLabel)
    }

    func test_product_row_priceQuantityLine_when_product_has_no_price_then_returns_properly_formatted_priceQuantityLine() {
        // Given
        let quantity: Decimal = 8
        let product = Product.fake().copy()

        // When
        let viewModel = ProductRowViewModel(product: product, quantity: quantity, canChangeQuantity: true)

        // Then
        assertEqual("8 × -", viewModel.priceQuantityLine)
    }

    // MARK: - `isConfigurable`

    func test_isConfigurable_is_false_for_bundle_product_when_feature_flag_is_disabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle")

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            canChangeQuantity: false,
                                            featureFlagService: createFeatureFlagService(productBundlesInOrderForm: false))

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_is_false_for_bundle_product_with_empty_bundle_items() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle")

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            canChangeQuantity: false,
                                            featureFlagService: createFeatureFlagService(productBundlesInOrderForm: true))

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_is_true_for_bundle_product_with_bundle_items_and_configure_closure() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", bundledItems: [.fake()])

        // When
        let viewModel = ProductRowViewModel(product: product,
                                            canChangeQuantity: false,
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
                                            canChangeQuantity: false,
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
                                                canChangeQuantity: false,
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
