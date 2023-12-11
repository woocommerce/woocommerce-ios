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
        let product = Product.fake()
        let childProductRows = [createViewModel(), createViewModel()]

        // When
        let rowViewModel = createViewModel()
        let viewModel = CollapsibleProductCardViewModel(productRow: rowViewModel, childProductRows: childProductRows)

        // Then
        XCTAssertEqual(viewModel.childProductRows.count, 2)
    }

    func test_view_model_updates_price_label_when_quantity_changes() {
        // Given
        let product = Product.fake().copy(price: "2.50")
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = createViewModel(productViewModel: .init(product: product, currencyFormatter: currencyFormatter))
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        let expectedPriceLabel = "$5.00"
        XCTAssertTrue(viewModel.productViewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productViewModel.productDetailsLabel)\"")
    }

    func test_isReadOnly_and_hasParentProduct_are_false_by_default() {
        // When
        let viewModel = CollapsibleProductRowCardViewModel(imageURL: nil,
                                                           name: "",
                                                           sku: nil,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 1,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertFalse(viewModel.isReadOnly)
        XCTAssertFalse(viewModel.hasParentProduct)
    }

    // MARK: - Quantity

    func test_ProductStepperViewModel_and_ProductRowViewModel_quantity_have_the_same_initial_value() {
        // When
        let viewModel = createViewModel(stepperViewModel: .init(quantity: 2,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 2)
        XCTAssertEqual(viewModel.productViewModel.quantity, 2)
    }

    func test_ProductStepperViewModel_quantity_change_updates_ProductRowViewModel_quantity() {
        // Given
        let viewModel = createViewModel(stepperViewModel: .init(quantity: 2,
                                                                name: "",
                                                                quantityUpdatedCallback: { _ in }))

        // When
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 3)
        XCTAssertEqual(viewModel.productViewModel.quantity, 3)
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

    func test_when_product_row_discount_is_nil_then_viewModel_hasDiscount_is_false() {
        // Given
        let price = "2.50"
        let product = Product.fake().copy(price: price)

        // When
        let viewModel = createViewModel(productViewModel: .init(product: product, discount: nil, quantity: 1))

        // Then
        XCTAssertFalse(viewModel.hasDiscount)
    }

    func test_when_product_row_discount_is_not_nil_then_viewModel_hasDiscount() {
        // Given
        let price = "2.50"
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        // When
        let viewModel = createViewModel(productViewModel: .init(product: product, discount: discount, quantity: 1))

        // Then
        XCTAssertTrue(viewModel.hasDiscount)
    }

    // MARK: - `totalPriceAfterDiscountLabel`

    func test_totalPriceAfterDiscountLabel_when_product_row_has_one_item_and_discount_then_returns_properly_formatted_price_after_discount() {
        // Given
        let price = "2.50"
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        // When
        let viewModel = createViewModel(productViewModel: .init(product: product, discount: discount, quantity: 1))

        // Then
        assertEqual("$2.00", viewModel.totalPriceAfterDiscountLabel)
    }

    func test_totalPriceAfterDiscountLabel_when_product_row_has_multiple_item_and_discount_then_returns_properly_formatted_price_after_discount() {
        // Given
        let price = "2.50"
        let quantity: Decimal = 10
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        // When
        let viewModel = createViewModel(productViewModel: .init(product: product, discount: discount, quantity: quantity),
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
                                        manageStock: product.manageStock,
                                        productViewModel: .init(product: product))

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
}

private extension CollapsibleProductRowCardViewModelTests {
    func createViewModel(hasParentProduct: Bool = false,
                         isReadOnly: Bool = false,
                         isConfigurable: Bool = false,
                         imageURL: URL? = nil,
                         name: String = "",
                         sku: String? = nil,
                         productTypeDescription: String = "",
                         attributes: [VariationAttributeViewModel] = [],
                         stockStatus: ProductStockStatus = .inStock,
                         stockQuantity: Decimal? = nil,
                         manageStock: Bool = false,
                         productViewModel: ProductRowViewModel = .init(product: .fake()),
                         stepperViewModel: ProductStepperViewModel = .init(quantity: 1, name: "", quantityUpdatedCallback: { _ in }),
                         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()),
                         analytics: Analytics = ServiceLocator.analytics,
                         configure: (() -> Void)? = nil) -> CollapsibleProductRowCardViewModel {
        CollapsibleProductRowCardViewModel(hasParentProduct: hasParentProduct,
                                           isReadOnly: isReadOnly,
                                           isConfigurable: isConfigurable,
                                           imageURL: imageURL,
                                           name: name,
                                           sku: sku,
                                           productTypeDescription: productTypeDescription,
                                           attributes: attributes,
                                           stockStatus: stockStatus,
                                           stockQuantity: stockQuantity,
                                           manageStock: manageStock,
                                           productViewModel: productViewModel,
                                           stepperViewModel: stepperViewModel,
                                           currencyFormatter: currencyFormatter,
                                           analytics: analytics,
                                           configure: configure)
    }
}
