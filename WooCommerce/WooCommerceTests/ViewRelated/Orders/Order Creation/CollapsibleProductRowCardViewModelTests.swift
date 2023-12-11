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
        let childProductRows = [ProductRowViewModel(product: .fake()),
                                ProductRowViewModel(product: .fake())]
            .map {
                CollapsibleProductRowCardViewModel(productTypeDescription: product.productType.description,
                                                   attributes: [],
                                                   stockStatus: product.productStockStatus,
                                                   stockQuantity: product.stockQuantity,
                                                   manageStock: product.manageStock,
                                                   productViewModel: $0,
                                                   stepperViewModel: .init(quantity: 1,
                                                                           name: "",
                                                                           quantityUpdatedCallback: { _ in }))
            }

        // When
        let rowViewModel = CollapsibleProductRowCardViewModel(productTypeDescription: product.productType.description,
                                                              attributes: [],
                                                              stockStatus: product.productStockStatus,
                                                              stockQuantity: product.stockQuantity,
                                                              manageStock: product.manageStock,
                                                              productViewModel: .init(product: product),
                                                              stepperViewModel: .init(quantity: 1,
                                                                                      name: "",
                                                                                      quantityUpdatedCallback: { _ in }))
        let viewModel = CollapsibleProductCardViewModel(productRow: rowViewModel, childProductRows: childProductRows)

        // Then
        XCTAssertEqual(viewModel.childProductRows.count, 2)
    }

    func test_view_model_updates_price_label_when_quantity_changes() {
        // Given
        let product = Product.fake().copy(price: "2.50")
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = CollapsibleProductRowCardViewModel(productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: product, currencyFormatter: currencyFormatter),
                                                           stepperViewModel: .init(quantity: 1,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        let expectedPriceLabel = "$5.00"
        XCTAssertTrue(viewModel.productViewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productViewModel.productDetailsLabel)\"")
    }

    func test_isReadOnly_and_hasParentProduct_are_false_by_default() {
        // When
        let viewModel = CollapsibleProductRowCardViewModel(productTypeDescription: "",
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
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 2,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 2)
        XCTAssertEqual(viewModel.productViewModel.quantity, 2)
    }

    func test_ProductStepperViewModel_quantity_change_updates_ProductRowViewModel_quantity() {
        // Given
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 2,
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
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 2,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }),
                                                           analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackAddDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountAddButtonTapped.rawValue)
    }

    func test_productRow_when_edit_discount_button_is_tapped_then_orderProductDiscountEditButtonTapped_is_tracked() {
        // Given
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 2,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }),
                                                           analytics: WooAnalytics(analyticsProvider: analytics))

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
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: product, discount: nil, quantity: 1),
                                                           stepperViewModel: .init(quantity: 2,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertFalse(viewModel.hasDiscount)
    }

    func test_when_product_row_discount_is_not_nil_then_viewModel_hasDiscount() {
        // Given
        let price = "2.50"
        let discount: Decimal = 0.50
        let product = Product.fake().copy(price: price)

        // When
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: product, discount: discount, quantity: 1),
                                                           stepperViewModel: .init(quantity: 2,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

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
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: product, discount: discount, quantity: 1),
                                                           stepperViewModel: .init(quantity: 1,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

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
        let viewModel = CollapsibleProductRowCardViewModel(hasParentProduct: false,
                                                           isReadOnly: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: product, discount: discount, quantity: quantity),
                                                           stepperViewModel: .init(quantity: quantity,
                                                                                   name: "",
                                                                                   quantityUpdatedCallback: { _ in }))

        // Then
        assertEqual("$24.50", viewModel.totalPriceAfterDiscountLabel)
    }

    // MARK: - `isConfigurable`

    func test_isConfigurable_set_to_false_if_true_and_configure_is_nil() {
        // Given
        let viewModel = CollapsibleProductRowCardViewModel(isConfigurable: true,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 1, name: "", quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertFalse(viewModel.isConfigurable)
    }

    func test_isConfigurable_set_to_true_if_true_and_configure_is_not_nil() {
        // Given
        let viewModel = CollapsibleProductRowCardViewModel(isConfigurable: true,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 1, name: "", quantityUpdatedCallback: { _ in }),
                                                           configure: {})

        // Then
        XCTAssertTrue(viewModel.isConfigurable)
    }

    func test_isConfigurable_set_to_false_if_false() {
        // Given
        let viewModel = CollapsibleProductRowCardViewModel(isConfigurable: false,
                                                           productTypeDescription: "",
                                                           attributes: [],
                                                           stockStatus: .inStock,
                                                           stockQuantity: nil,
                                                           manageStock: false,
                                                           productViewModel: .init(product: .fake()),
                                                           stepperViewModel: .init(quantity: 1, name: "", quantityUpdatedCallback: { _ in }),
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
        let viewModel = CollapsibleProductRowCardViewModel(isConfigurable: false,
                                                           productTypeDescription: product.productType.description,
                                                           attributes: [],
                                                           stockStatus: product.productStockStatus,
                                                           stockQuantity: product.stockQuantity,
                                                           manageStock: product.manageStock,
                                                           productViewModel: .init(product: product),
                                                           stepperViewModel: .init(quantity: 1, name: product.name, quantityUpdatedCallback: { _ in }))

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
        let viewModel = CollapsibleProductRowCardViewModel(isConfigurable: false,
                                                           productTypeDescription: ProductType.variable.description,
                                                           attributes: attributes,
                                                           stockStatus: variation.stockStatus,
                                                           stockQuantity: variation.stockQuantity,
                                                           manageStock: variation.manageStock,
                                                           productViewModel: .init(productVariation: variation, name: "", displayMode: .attributes(attributes)),
                                                           stepperViewModel: .init(quantity: 1, name: "", quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertTrue(viewModel.productDetailsLabel.contains(variationAttribute), "Label should contain variation attribute")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(stockStatus.description), "Label should contain stock status")
    }

    func test_productDetailsLabel_contains_product_type_and_stock_status_for_configurable_bundle_product() {
        // Given
        let stockStatus = ProductStockStatus.inStock
        let product = Product.fake().copy(productTypeKey: ProductType.bundle.rawValue, stockStatusKey: stockStatus.rawValue, bundledItems: [.fake()])

        // When
        let viewModel = CollapsibleProductRowCardViewModel(isConfigurable: true,
                                                           productTypeDescription: product.productType.description,
                                                           attributes: [],
                                                           stockStatus: product.productStockStatus,
                                                           stockQuantity: product.stockQuantity,
                                                           manageStock: product.manageStock,
                                                           productViewModel: .init(product: product),
                                                           stepperViewModel: .init(quantity: 1, name: product.name, quantityUpdatedCallback: { _ in }))

        // Then
        XCTAssertTrue(viewModel.productDetailsLabel.contains(ProductType.bundle.description), "Label should contain product type (Bundle)")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(stockStatus.description), "Label should contain stock status")
    }
}
