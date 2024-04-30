import WooFoundation
import XCTest
import Yosemite
@testable import WooCommerce

final class CollapsibleProductRowCardViewModelTests: XCTestCase {
    private var analytics: MockAnalyticsProvider!

    override func setUp() {
        super.setUp()
        analytics = MockAnalyticsProvider()
    }

    override func tearDown() {
        analytics = nil
        super.tearDown()
    }

    func test_viewModel_is_created_with_correct_initial_values_from_product_with_child_product_rows() {
        // Given
        let childProductRows = [createViewModel(), createViewModel()]

        // When
        let rowViewModel = createViewModel()
        let viewModel = CollapsibleProductCardViewModel(productRow: rowViewModel, childProductRows: childProductRows)

        // Then
        XCTAssertEqual(viewModel.childProductRows.count, 2)
    }

    func test_view_model_updates_price_label_when_quantity_changes() throws {
        // Given
        let price = "2.50"
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = createViewModel(price: price, currencyFormatter: currencyFormatter)
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        let expectedPriceLabel = "$5.00"
        let actualPriceLabel = try XCTUnwrap(viewModel.priceSummaryViewModel.priceBeforeDiscountsLabel)
        XCTAssertTrue(actualPriceLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(actualPriceLabel)\"")
    }

    func test_isReadOnly_and_hasParentProduct_are_false_by_default() {
        // When
        let viewModel = CollapsibleProductRowCardViewModel(id: 1,
                                                           productOrVariationID: 2,
                                                           imageURL: nil,
                                                           name: "",
                                                           sku: nil,
                                                           price: nil,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           stepperViewModel: .init(quantity: 1,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertFalse(viewModel.isReadOnly)
        XCTAssertFalse(viewModel.hasParentProduct)
    }

    // MARK: - Quantity

    func test_stepperViewModel_and_priceSummaryViewModel_quantity_have_the_same_initial_value() {
        // When
        let viewModel = createViewModel(stepperViewModel: .init(quantity: 2,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 2)
        XCTAssertEqual(viewModel.priceSummaryViewModel.quantity, 2)
    }

    func test_stepperViewModel_quantity_change_updates_priceSummaryViewModel_quantity() {
        // Given
        let viewModel = createViewModel(stepperViewModel: .init(quantity: 2,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // When
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 3)
        XCTAssertEqual(viewModel.priceSummaryViewModel.quantity, 3)
    }

    // MARK: - Analytics

    func test_productRow_when_add_discount_button_is_tapped_then_orderProductDiscountAddButtonTapped_is_tracked() {
        // Given
        let viewModel = createViewModel(analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackAddDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountAddButtonTapped.rawValue)
    }

    func test_productRow_when_edit_discount_button_is_tapped_then_orderProductDiscountEditButtonTapped_is_tracked() {
        // Given
        let viewModel = createViewModel(analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackEditDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountEditButtonTapped.rawValue)
    }

    // MARK: - `hasDiscount`

    func test_when_discount_is_nil_then_viewModel_hasDiscount_is_false() {
        // Given
        let viewModel = createViewModel(discount: nil)

        // Then
        XCTAssertFalse(viewModel.hasDiscount)
    }

    func test_when_discount_is_not_nil_then_viewModel_hasDiscount() {
        // Given
        let viewModel = createViewModel(discount: 0.50)

        // Then
        XCTAssertTrue(viewModel.hasDiscount)
    }

    // MARK: - `totalPriceAfterDiscountLabel`

    func test_totalPriceAfterDiscountLabel_when_product_row_has_one_item_and_discount_then_returns_properly_formatted_price_after_discount() {
        // Given
        let price = "2.50"
        let discount: Decimal = 0.50

        // When
        let viewModel = createViewModel(price: price, discount: discount)

        // Then
        assertEqual("$2.00", viewModel.totalPriceAfterDiscountLabel)
    }

    func test_totalPriceAfterDiscountLabel_when_product_row_has_multiple_item_and_discount_then_returns_properly_formatted_price_after_discount() {
        // Given
        let price = "2.50"
        let quantity: Decimal = 10
        let discount: Decimal = 0.50

        // When
        let viewModel = createViewModel(price: price,
                                        discount: discount,
                                        stepperViewModel: .init(quantity: quantity,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        assertEqual("$24.50", viewModel.totalPriceAfterDiscountLabel)
    }

    // MARK: - `isConfigurable`

    func test_isConfigurable_set_to_false_if_true_and_configure_is_nil() {
        // Given
        let viewModel = createViewModel(isConfigurable: true)

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_set_to_true_if_true_and_configure_is_not_nil() {
        // Given
        let viewModel = createViewModel(isConfigurable: true,
                                                           configure: {})

        // Then
        XCTAssertTrue(viewModel.isConfigurable)
    }

    func test_isConfigurable_set_to_false_if_false() {
        // Given
        let viewModel = createViewModel(isConfigurable: false,
                                        configure: {})

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    // MARK: - `productDetailsLabel`

    func test_productDetailsLabel_is_stock_status_for_non_configurable_product() {
        // Given
        let stockStatus = ProductStockStatus.inStock
        let product = Product.fake().copy(stockStatusKey: stockStatus.rawValue)

        // When
        let viewModel = createViewModel(productTypeDescription: product.productType.description,
                                        attributes: [],
                                        stockStatus: product.productStockStatus,
                                        stockQuantity: product.stockQuantity,
                                        manageStock: product.manageStock)

        // Then
        assertEqual(stockStatus.description, viewModel.productDetailsLabel)
    }

    func test_productDetailsLabel_contains_attributes_and_stock_status_for_non_configurable_product_variation() {
        // Given
        let stockStatus = ProductStockStatus.inStock
        let variationAttribute = "Blue"
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: variationAttribute)],
                                                     stockStatus: stockStatus)
        let attributes = [VariationAttributeViewModel(name: "Color", value: "Blue"), VariationAttributeViewModel(name: "Size")]

        // When
        let viewModel = createViewModel(productTypeDescription: ProductType.variable.description,
                                        attributes: attributes,
                                        stockStatus: variation.stockStatus,
                                        stockQuantity: variation.stockQuantity,
                                        manageStock: variation.manageStock)

        // Then
        XCTAssertTrue(viewModel.productDetailsLabel.contains(variationAttribute), "Label should contain variation attribute")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(stockStatus.description), "Label should contain stock status")
    }

    func test_productDetailsLabel_contains_product_type_and_stock_status_for_configurable_bundle_product() {
        // Given
        let stockStatus = ProductStockStatus.inStock
        let product = Product.fake().copy(productTypeKey: ProductType.bundle.rawValue, stockStatusKey: stockStatus.rawValue, bundledItems: [.fake()])

        // When
        let viewModel = createViewModel(isConfigurable: true,
                                        productTypeDescription: product.productType.description,
                                        attributes: [],
                                        stockStatus: product.productStockStatus,
                                        stockQuantity: product.stockQuantity,
                                        manageStock: product.manageStock)

        // Then
        XCTAssertTrue(viewModel.productDetailsLabel.contains(ProductType.bundle.description), "Label should contain product type (Bundle)")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(stockStatus.description), "Label should contain stock status")
    }

    // MARK: - `skuLabel`

    func test_sku_label_is_formatted_correctly_for_product_with_sku() {
        // Given
        let sku = "123456"

        // When
        let viewModel = createViewModel(sku: sku)

        // Then
        let format = NSLocalizedString("CollapsibleProductRowCardViewModel.skuFormat",
                                       value: "SKU: %1$@",
                                       comment: "SKU label for a product in an order. The variable shows the SKU of the product.")
        let expectedSKULabel = String.localizedStringWithFormat(format, sku)
        assertEqual(expectedSKULabel, viewModel.skuLabel)
    }

    func test_sku_label_is_empty_for_product_when_sku_is_empty_or_nil() {
        // Given
        let emptyString = ""

        // When
        let emptySKUviewModel = createViewModel(sku: emptyString)
        let nilSKUViewModel = createViewModel(sku: nil)

        // Then
        assertEqual(emptyString, emptySKUviewModel.skuLabel)
        assertEqual(emptyString, nilSKUViewModel.skuLabel)
    }

    func test_productRow_when_initialized_with_product_subscription_type_then_contains_product_subscription_details() {
        // Given
        let productSubscription: ProductSubscription = createFakeSubscription()
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          subscription: productSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name)

        // Then
        XCTAssertEqual(viewModel.productSubscriptionDetails?.length, productSubscription.length)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.period, productSubscription.period)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.price, productSubscription.price)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.signUpFee, productSubscription.signUpFee)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.trialLength, productSubscription.trialLength)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.trialPeriod, productSubscription.trialPeriod)
    }

    func test_productRow_when_has_product_subscription_then_shouldShowProductSubscriptionsDetails() {
        // Given
        let productSubscription: ProductSubscription = createFakeSubscription()
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          subscription: productSubscription)

        // When
        let defaultViewModel = createViewModel()
        let viewModelWithSubscriptionProduct = createViewModel(id: product.productID,
                                                               productSubscriptionDetails: product.subscription,
                                                               name: product.name)

        // Then
        XCTAssertFalse(defaultViewModel.shouldShowProductSubscriptionsDetails)
        XCTAssertTrue(viewModelWithSubscriptionProduct.shouldShowProductSubscriptionsDetails)
    }

    func test_productRow_when_has_no_product_subscription_then_subscriptionBillingDetailsLabel_is_nil() {
        // Given, When
        let viewModel = createViewModel()

        // Then
        XCTAssertNil(viewModel.subscriptionBillingIntervalLabel)
    }

    func test_productRow_when_expectedPeriodInterval_is_zero_then_subscriptionBillingDetailsLabel_is_nil() {
        // Handles the edge case of the Subscriptions API allowing a zero-period value billing interval
        // to be passed to the subscription details. In this case, we won't render Subscription details.

        // Given
        let expectedPeriodInterval = "0"
        let expectedPeriod = SubscriptionPeriod.month
        let productSubscription: ProductSubscription = createFakeSubscription(periodInterval: expectedPeriodInterval,
                                                                              period: expectedPeriod)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          subscription: productSubscription)
        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name)
        // Then
        XCTAssertNil(viewModel.subscriptionBillingIntervalLabel)
    }

    func test_productRow_when_expectedPeriodInterval_is_one_then_subscriptionBillingDetailsLabel_is_singular() {
        // Given
        let expectedPeriodInterval = "1"
        let expectedPeriod = SubscriptionPeriod.month
        let productSubscription: ProductSubscription = createFakeSubscription(periodInterval: expectedPeriodInterval,
                                                                              period: expectedPeriod)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          subscription: productSubscription)
        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name)
        // Then
        XCTAssertEqual(viewModel.subscriptionBillingIntervalLabel, "Every 1 month")
    }

    func test_productRow_when_expectedPeriodInterval_is_more_than_one_then_subscriptionBillingDetailsLabel_is_plural() {
        // Given
        let expectedPeriodInterval = "2"
        let expectedPeriod = SubscriptionPeriod.month
        let productSubscription: ProductSubscription = createFakeSubscription(periodInterval: expectedPeriodInterval,
                                                                              period: expectedPeriod)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          subscription: productSubscription)
        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name)
        // Then
        XCTAssertEqual(viewModel.subscriptionBillingIntervalLabel, "Every 2 months")
    }

    func test_productRow_when_subscriptionPrice_is_nil_then_productSubscriptionDetails_is_nil() {
        // Given
        let productPrice = "10"
        let nilProductSubscription: ProductSubscription? = nil
        let product = Product.fake().copy(productID: 12,
                                          name: "Not a subscription product",
                                          price: productPrice,
                                          subscription: nilProductSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name,
                                        price: productPrice)

        // Then
        XCTAssertEqual(viewModel.price, productPrice)
        XCTAssertEqual(viewModel.subscriptionPrice, nil)
        XCTAssertEqual(viewModel.productSubscriptionDetails, nil)
    }

    func test_productRow_when_subscriptionPrice_is_zero_then_productSubscriptionDetails_is_nil() {
        // Given
        let productPrice = "10"
        let zeroPriceProductSubscription: ProductSubscription? = createFakeSubscription(price: "0")
        let product = Product.fake().copy(productID: 12,
                                          name: "A zero-priced subscription product",
                                          price: productPrice,
                                          subscription: zeroPriceProductSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name,
                                        price: productPrice)

        // Then
        XCTAssertEqual(viewModel.price, productPrice)
        XCTAssertEqual(viewModel.subscriptionPrice, nil)
        XCTAssertEqual(viewModel.productSubscriptionDetails, zeroPriceProductSubscription)
    }

    func test_productRow_when_subscriptionPrice_is_not_zero_then_productSubscriptionDetails_is_formatted_price() {
        // Given
        let productPrice = "17"
        let expectedFormattedPrice = "$17.00"
        let productSubscription: ProductSubscription? = createFakeSubscription(price: productPrice)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          price: productPrice,
                                          subscription: productSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name,
                                        price: productPrice)

        // Then
        XCTAssertEqual(viewModel.price, productPrice)
        XCTAssertEqual(viewModel.subscriptionPrice, expectedFormattedPrice)
        XCTAssertEqual(viewModel.productSubscriptionDetails, productSubscription)
    }

    func test_productRow_when_item_has_product_price_different_than_subscription_price_then_product_price_is_used() {
        // Given
        let productPrice = "5"
        let subscriptionPrice = "10"
        let productQuantity = Decimal(10)
        let expectedFormattedPrice = "$50.00"

        let productSubscription: ProductSubscription? = createFakeSubscription(price: subscriptionPrice)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          price: productPrice,
                                          subscription: productSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name,
                                        price: productPrice,
                                        stepperViewModel: .init(quantity: productQuantity,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.price, productPrice)
        XCTAssertEqual(viewModel.subscriptionPrice, expectedFormattedPrice)
        XCTAssertEqual(viewModel.productSubscriptionDetails, productSubscription)
    }

    func test_productRow_when_item_has_more_than_one_quantity_then_subscriptionPrice_is_formatted_properly() {
        // Given
        let productPrice = "10"
        let productQuantity = Decimal(10)
        let expectedFormattedPrice = "$100.00"

        let productSubscription = createFakeSubscription(price: productPrice)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          price: productPrice,
                                          subscription: productSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name,
                                        price: productPrice,
                                        stepperViewModel: .init(quantity: productQuantity,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.price, productPrice)
        XCTAssertEqual(viewModel.subscriptionPrice, expectedFormattedPrice)
        XCTAssertEqual(viewModel.productSubscriptionDetails, productSubscription)
    }

    func test_productRow_when_price_and_subscriptionPrice_are_different_then_are_assigned_correctly() {
        // Given
        let productPrice = "17"
        let subscriptionPrice = "10"
        let productSubscription: ProductSubscription? = createFakeSubscription(price: subscriptionPrice)
        let product = Product.fake().copy(productID: 12,
                                          name: "A subscription product",
                                          price: productPrice,
                                          subscription: productSubscription)

        // When
        let viewModel = createViewModel(id: product.productID,
                                        productSubscriptionDetails: product.subscription,
                                        name: product.name,
                                        price: productPrice)

        // Then
        XCTAssertEqual(viewModel.price, productPrice)
        XCTAssertEqual(viewModel.productSubscriptionDetails?.price, subscriptionPrice)
    }

    func test_productRow_when_subscription_signupFee_is_nil_or_zero_then_subscriptionConditionsSignupLabel_is_nil() {
        // Given
        let subscriptions = [
            createFakeSubscription(signUpFee: nil),
            createFakeSubscription(signUpFee: ""),
            createFakeSubscription(signUpFee: "0"),
        ]

        for productSubscription in subscriptions.makeIterator() {
            // When
            let viewModel = createViewModel(productSubscriptionDetails: productSubscription)

            // Then
            XCTAssertNil(viewModel.subscriptionConditionsSignupLabel)
        }
    }

    func test_productRow_when_subscription_signupFee_is_not_nil_then_signUpFee_is_formatted() {
        // Given
        let signUpFee = "0.60"
        let expectedSignUpFee = "$0.60"
        let expectedSignUpFeeSummary: String? = nil
        let productSubscription = createFakeSubscription(signUpFee: signUpFee)

        // When
        let viewModel = createViewModel(productSubscriptionDetails: productSubscription)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsSignupFee, expectedSignUpFee)
        XCTAssertEqual(viewModel.signupFeeSummary, expectedSignUpFeeSummary)
    }

    func test_productRow_when_subscription_has_signupFee_and_order_has_single_item_then_expectedSignUpFeeSummary_is_nil() {
        // Given
        let signUpFee = "0.60"
        let quantity = 1
        let expectedSignUpFees = "$0.60"
        let expectedSignUpFeeSummary: String? = nil
        let productSubscription = createFakeSubscription(signUpFee: signUpFee)

        // When
        let viewModel = createViewModel(productSubscriptionDetails: productSubscription,
                                        stepperViewModel: .init(quantity: Decimal(quantity),
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsSignupFee, expectedSignUpFees)
        XCTAssertEqual(viewModel.signupFeeSummary, expectedSignUpFeeSummary)
    }

    func test_productRow_when_subscription_has_signupFee_and_order_has_multiple_items_then_signupFees_are_multiplied_and_formatted() {
        // Given
        let signUpFee = "0.60"
        let quantity = 10
        let expectedSignUpFees = "$6.00"
        let expectedSignUpFeeSummary = "10 × $6.00"
        let productSubscription = createFakeSubscription(signUpFee: signUpFee)

        // When
        let viewModel = createViewModel(productSubscriptionDetails: productSubscription,
                                        stepperViewModel: .init(quantity: Decimal(quantity),
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsSignupFee, expectedSignUpFees)
        XCTAssertEqual(viewModel.signupFeeSummary, expectedSignUpFeeSummary)
    }

    func test_productRow_when_subscription_signupFee_is_not_nil_then_signUpFee_label_is_formatted() {
        // Given
        let signUpFee = "0.60"
        let expectedSignUpFeeLabel = "$0.60 signup"
        let productSubscription = createFakeSubscription(signUpFee: signUpFee)

        // When
        let viewModel = createViewModel(productSubscriptionDetails: productSubscription)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsSignupLabel, expectedSignUpFeeLabel)
    }

    func test_productRow_when_subscription_free_trial_is_nil_or_zero_then_subscriptionConditionsFreeTrialLabel_is_nil() {
        // Given
        let subscriptions = [
            createFakeSubscription(trialLength: nil),
            createFakeSubscription(trialLength: "0"),
            createFakeSubscription(trialLength: ""),
        ]

        for productSubscription in subscriptions.makeIterator() {
            // When
            let viewModel = createViewModel(productSubscriptionDetails: productSubscription)

            // Then
            XCTAssertNil(viewModel.subscriptionConditionsFreeTrialLabel)
        }
    }

    func test_productRow_when_subscription_free_trialLength_is_one_then_subscriptionConditionsFreeTrialLabel_is_singular() {
        // Given
        let trialLength = "1"
        let trialPeriod = SubscriptionPeriod.week
        let expectedFreeTrialLabel = "1 week free"
        let productSubscription = createFakeSubscription(trialLength: trialLength, trialPeriod: trialPeriod)

        // When
        let viewModel = createViewModel(productSubscriptionDetails: productSubscription)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsFreeTrialLabel, expectedFreeTrialLabel)

    }

    func test_productRow_when_subscription_free_trialLength_is_more_than_one_then_subscriptionConditionsFreeTrialLabel_is_plural() {
        // Given
        let trialLength = "5"
        let trialPeriod = SubscriptionPeriod.day
        let expectedFreeTrialLabel = "5 days free"
        let productSubscription = createFakeSubscription(trialLength: trialLength, trialPeriod: trialPeriod)

        // When
        let viewModel = createViewModel(productSubscriptionDetails: productSubscription)

        // Then
        XCTAssertEqual(viewModel.subscriptionConditionsFreeTrialLabel, expectedFreeTrialLabel)

    }
}

private extension CollapsibleProductRowCardViewModelTests {
    func createViewModel(id: Int64 = 1,
                         productOrVariationID: Int64 = 1,
                         hasParentProduct: Bool = false,
                         isReadOnly: Bool = false,
                         isConfigurable: Bool = false,
                         productSubscriptionDetails: ProductSubscription? = nil,
                         imageURL: URL? = nil,
                         name: String = "",
                         sku: String? = nil,
                         price: String? = nil,
                         discount: Decimal? = nil,
                         productTypeDescription: String = "",
                         attributes: [VariationAttributeViewModel] = [],
                         stockStatus: ProductStockStatus = .inStock,
                         stockQuantity: Decimal? = nil,
                         manageStock: Bool = false,
                         stepperViewModel: ProductStepperViewModel = .init(quantity: 1, name: "", quantityUpdatedCallback: { _ in }),
                         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()),
                         analytics: Analytics = ServiceLocator.analytics,
                         configure: (() -> Void)? = nil) -> CollapsibleProductRowCardViewModel {
        CollapsibleProductRowCardViewModel(id: id,
                                           productOrVariationID: productOrVariationID,
                                           hasParentProduct: hasParentProduct,
                                           isReadOnly: isReadOnly,
                                           isConfigurable: isConfigurable,
                                           productSubscriptionDetails: productSubscriptionDetails,
                                           imageURL: imageURL,
                                           name: name,
                                           sku: sku,
                                           price: price,
                                           discount: discount,
                                           productTypeDescription: productTypeDescription,
                                           attributes: attributes,
                                           stockStatus: stockStatus,
                                           stockQuantity: stockQuantity,
                                           manageStock: manageStock,
                                           stepperViewModel: stepperViewModel,
                                           currencyFormatter: currencyFormatter,
                                           analytics: analytics,
                                           configure: configure)
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
