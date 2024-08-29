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
        let imageURLString = "https://woocommerce.com/woocommerce.jpg"
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
        let imageURLString = "https://woocommerce.com/woocommerce.jpg"
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

    func test_bundle_stock_status_used_for_product_bundles_when_insufficient_stock() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", stockStatusKey: "instock", bundleStockStatus: .insufficientStock)

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedStockText = ProductStockStatus.insufficientStock.description
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockText),
                      "Expected label to contain \"\(expectedStockText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_product_stock_status_used_for_product_bundles_when_backordered() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", stockStatusKey: "onbackorder", bundleStockStatus: .inStock)

        // When
        let viewModel = ProductRowViewModel(product: product)

        // Then
        let expectedStockText = ProductStockStatus.onBackOrder.description
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockText),
                      "Expected label to contain \"\(expectedStockText)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_bundle_stock_quantity_used_for_product_bundles() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle", manageStock: false, stockQuantity: 5, stockStatusKey: "instock", bundleStockQuantity: 1)

        // When
        let viewModel = ProductRowViewModel(product: product)

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

    // MARK: - `productSubscriptionDetails`
    //
    func test_productRow_when_product_type_is_subscription_and_contains_subscription_metadata_then_productRow_has_subscription_metadata() {
        // Given
        let rowID = Int64(0)
        let fakeSubscription: ProductSubscription = createFakeSubscription()
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: fakeSubscription)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: fakeSubscription)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, product.productID)
        XCTAssertEqual(viewModel.name, product.name)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.length, fakeSubscription.length)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.period, fakeSubscription.period)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.price, fakeSubscription.price)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.signUpFee, fakeSubscription.signUpFee)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.trialLength, fakeSubscription.trialLength)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.trialPeriod, fakeSubscription.trialPeriod)
    }

    func test_productRow_variation_when_product_type_is_subscription_and_contains_subscription_metadata_then_productRow_variation_has_subscription_metadata() {
        // Given
        let rowID = Int64(0)
        let fakeSubscription: ProductSubscription = createFakeSubscription()
        let name = "Blue - Any Size"
        let productVariation = ProductVariation.fake().copy(productVariationID: 12,
                                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")],
                                                            subscription: fakeSubscription)

        // When
        let viewModel = ProductRowViewModel(id: rowID, productVariation: productVariation, name: name, displayMode: .stock)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, productVariation.productVariationID)
        XCTAssertEqual(viewModel.name, name)
        XCTAssertNotNil(viewModel.productSubscriptionDetails)
    }

    func test_productRow_when_product_type_is_not_subscription_but_contains_subscription_metadata_then_productRow_has_no_subscription_metadata() {
        // Given
        let rowID = Int64(0)
        let fakeSubscription: ProductSubscription = createFakeSubscription()
        let productTypeKey = "simple"

        let product = Product.fake().copy(productID: 12,
                                          name: "Not a subscription product anymore, but might have subscription metadata",
                                          productTypeKey: productTypeKey,
                                          subscription: fakeSubscription)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: fakeSubscription)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, product.productID)
        XCTAssertEqual(viewModel.name, product.name)
        XCTAssertNil(viewModel.productSubscriptionDetails)
    }

    func test_subscriptionBillingDetailsLabel_when_periodInterval_is_1_then_returns_singular_details() {
        // Given
        let rowID = Int64(0)
        let expectedPrice = "5"
        let expectedPeriodInterval = "1"
        let expectedPeriod = SubscriptionPeriod.month
        let expectedBillingDetailsLabel = "$5.00 / 1 month"
        let fakeSubscription: ProductSubscription = createFakeSubscription(price: expectedPrice,
                                                                           periodInterval: expectedPeriodInterval,
                                                                           period: expectedPeriod)
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: fakeSubscription)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: fakeSubscription)

        // Then
        XCTAssertEqual(viewModel.subscriptionBillingDetailsLabel, expectedBillingDetailsLabel)
    }

    func test_subscriptionBillingDetailsLabel_when_periodInterval_is_more_than_1_then_returns_pluralized_details() {
        // Given
        let rowID = Int64(0)
        let expectedPrice = "5"
        let expectedPeriodInterval = "3"
        let expectedPeriod = SubscriptionPeriod.month
        let expectedBillingDetailsLabel = "$5.00 / 3 months"
        let fakeSubscription: ProductSubscription = createFakeSubscription(price: expectedPrice,
                                                                           periodInterval: expectedPeriodInterval,
                                                                           period: expectedPeriod)
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: fakeSubscription)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: fakeSubscription)

        // Then
        XCTAssertEqual(viewModel.subscriptionBillingDetailsLabel, expectedBillingDetailsLabel)
    }

    func test_subscriptionConditionsLabel_when_has_signup_fees_and_trial_period_then_returns_expected_details() {
        // Given
        let rowID = Int64(0)
        let expectedSignUpFee = "0.6"
        let expectedTrialLength = "1"
        let expectedTrialPeriod = SubscriptionPeriod.week
        let expectedConditionsLabel = "$0.60 signup · 1 week free"
        let subs: ProductSubscription = createFakeSubscription(signUpFee: expectedSignUpFee,
                                                               trialLength: expectedTrialLength,
                                                               trialPeriod: expectedTrialPeriod)
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: subs)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: subs)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsLabel, expectedConditionsLabel)
    }

    func test_subscriptionConditionsLabel_when_has_no_signup_fees_but_has_trial_period_then_returns_expected_details() {
        // Given
        let rowID = Int64(0)
        let expectedTrialLength = "1"
        let expectedTrialPeriod = SubscriptionPeriod.week
        let expectedConditionsLabel = "1 week free"
        let subs: ProductSubscription = createFakeSubscription(signUpFee: nil,
                                                               trialLength: expectedTrialLength,
                                                               trialPeriod: expectedTrialPeriod)
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: subs)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: subs)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsLabel, expectedConditionsLabel)
    }

    func test_subscriptionConditionsLabel_when_has_no_free_trial_but_has_signup_fees_then_returns_expected_details() {
        // Given
        let rowID = Int64(0)
        let expectedSignUpFee = "0.6"
        let expectedConditionsLabel = "$0.60 signup"
        let subs: ProductSubscription = createFakeSubscription(signUpFee: expectedSignUpFee,
                                                               trialLength: nil,
                                                               trialPeriod: nil)
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: subs)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: subs)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsLabel, expectedConditionsLabel)
    }

    func test_subscriptionConditionsLabel_when_has_no_signup_fee_and_no_free_trial_then_returns_expected_details() {
        // Given
        let rowID = Int64(0)
        let subs: ProductSubscription = createFakeSubscription(signUpFee: nil, trialLength: nil, trialPeriod: nil)
        let productTypeKey = "subscription"

        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          productTypeKey: productTypeKey,
                                          subscription: subs)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: subs)

        // Then
        XCTAssertTrue(viewModel.subscriptionConditionsLabel.isEmpty)
    }

    func test_subscriptionConditionsLabel_when_signup_fee_is_zero_then_returns_no_signup_fee_in_label() {
        // Given
        let rowID = Int64(0)
        let signupFee = "0"
        let expectedTrialLength = "1"
        let expectedTrialPeriod = SubscriptionPeriod.week
        let expectedConditionsLabel = "1 week free"

        let subs: ProductSubscription = createFakeSubscription(signUpFee: signupFee,
                                                               trialLength: expectedTrialLength,
                                                               trialPeriod: expectedTrialPeriod)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product with zero signup fee",
                                          productTypeKey: "subscription",
                                          subscription: subs)

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, productSubscriptionDetails: subs)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsLabel, expectedConditionsLabel)
    }
}

private extension ProductRowViewModelTests {
    func createFeatureFlagService(productBundlesInOrderForm: Bool = false) -> FeatureFlagService {
        MockFeatureFlagService(productBundlesInOrderForm: productBundlesInOrderForm)
    }

    func createFakeSubscription(price: String? = "5",
                                periodInterval: String? = "1",
                                period: SubscriptionPeriod? = .month,
                                signUpFee: String? = "0.6",
                                trialLength: String? = "1",
                                trialPeriod: SubscriptionPeriod? = .week) -> ProductSubscription {
        ProductSubscription.fake().copy(length: "2",
                                        period: period,
                                        periodInterval: periodInterval,
                                        price: price,
                                        signUpFee: signUpFee,
                                        trialLength: trialLength,
                                        trialPeriod: trialPeriod)
    }
}
