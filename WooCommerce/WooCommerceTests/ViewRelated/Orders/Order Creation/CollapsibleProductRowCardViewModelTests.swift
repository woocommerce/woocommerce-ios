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

    func test_viewModel_is_created_with_correct_initial_values_from_order_item_and_product() throws {
        // Given
        let product = Product.fake().copy(productTypeKey: ProductType.bundle.rawValue,
                                          stockStatusKey: ProductStockStatus.inStock.description,
                                          images: [.fake().copy(src: "https://woo.com/woo.jpg")],
                                          bundledItems: [.fake()])
        let orderItem = OrderItem.fake().copy(itemID: 1, name: "Order Item", quantity: 2, price: 5, sku: "sku", subtotal: "5", total: "4", parent: 2)

        // When
        let discount: Decimal = 1
        let rowViewModel = CollapsibleProductRowCardViewModel(orderItem: orderItem,
                                                              product: product,
                                                              isReadOnly: false,
                                                              pricedIndividually: true,
                                                              discount: discount,
                                                              quantityUpdatedCallback: { _ in },
                                                              configure: {})

        // Then
        XCTAssertFalse(rowViewModel.isReadOnly)
        XCTAssertTrue(rowViewModel.hasDiscount)
        assertEqual(discount, rowViewModel.discount)

        // And it has expected values from order item
        assertEqual(orderItem.itemID, rowViewModel.id)
        assertEqual(orderItem.name, rowViewModel.name)
        XCTAssertTrue(rowViewModel.skuLabel.contains(try XCTUnwrap(orderItem.sku)))
        assertEqual(orderItem.price.description, rowViewModel.price)
        assertEqual(orderItem.quantity, rowViewModel.stepperViewModel.quantity)
        XCTAssertTrue(rowViewModel.hasParentProduct)

        // And it has expected values from product
        assertEqual(product.imageURL, rowViewModel.imageURL)
        XCTAssertTrue(rowViewModel.productDetailsLabel.contains(product.productStockStatus.description))
        XCTAssertTrue(rowViewModel.isConfigurable)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_order_item_and_product_variation() throws {
        // Given
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")],
                                                     image: .fake().copy(src: "https://woo.com/woo.jpg"),
                                                     stockStatus: .inStock)
        let variableProduct = Product.fake().copy(productTypeKey: ProductType.variable.description,
                                                  attributes: [.fake().copy(attributeID: 1, name: "Color", options: ["Blue", "Red"]),
                                                               .fake().copy(attributeID: 2, name: "Size", options: ["Small", "Large"])])
        let orderItem = OrderItem.fake().copy(itemID: 1, name: "Order Item", quantity: 2, price: 5, sku: "sku")

        // When
        let rowViewModel = CollapsibleProductRowCardViewModel(orderItem: orderItem,
                                                              variation: variation,
                                                              variableProduct: variableProduct,
                                                              isReadOnly: false,
                                                              pricedIndividually: true,
                                                              discount: nil,
                                                              quantityUpdatedCallback: { _ in })

        // Then
        XCTAssertFalse(rowViewModel.isReadOnly)
        XCTAssertFalse(rowViewModel.hasDiscount)
        XCTAssertNil(rowViewModel.discount)

        // And it has expected values from order item
        assertEqual(orderItem.itemID, rowViewModel.id)
        assertEqual(orderItem.name, rowViewModel.name)
        XCTAssertTrue(rowViewModel.skuLabel.contains(try XCTUnwrap(orderItem.sku)))
        assertEqual(orderItem.price.description, rowViewModel.price)
        assertEqual(orderItem.quantity, rowViewModel.stepperViewModel.quantity)
        XCTAssertFalse(rowViewModel.hasParentProduct)

        // And it has expected values from variation and variable product
        let expectedAttributes = [VariationAttributeViewModel(name: "Color", value: "Blue"), VariationAttributeViewModel(name: "Size")]
        let firstAttribute = try XCTUnwrap(expectedAttributes[0].nameOrValue)
        let secondAttribute = try XCTUnwrap(expectedAttributes[1].nameOrValue)
        assertEqual(variation.imageURL, rowViewModel.imageURL)
        XCTAssertTrue(rowViewModel.productDetailsLabel.contains(firstAttribute), "Product Details Label: \(rowViewModel.productDetailsLabel)")
        XCTAssertTrue(rowViewModel.productDetailsLabel.contains(secondAttribute))
        XCTAssertTrue(rowViewModel.productDetailsLabel.contains(variation.stockStatus.description))
        XCTAssertFalse(rowViewModel.isConfigurable)
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
}

private extension CollapsibleProductRowCardViewModelTests {
    func createViewModel(id: Int64 = 1,
                         productOrVariationID: Int64 = 1,
                         hasParentProduct: Bool = false,
                         isReadOnly: Bool = false,
                         isConfigurable: Bool = false,
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
}
