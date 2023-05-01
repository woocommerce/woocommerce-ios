import XCTest
import Yosemite
import WooFoundation

@testable import WooCommerce

final class DefaultProductFormTableViewModelTests: XCTestCase {
    func test_simple_product_inventory_row_details_shows_stock_status_when_stock_management_is_disabled_without_sku() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue,
                                          sku: "",
                                          manageStock: false,
                                          stockStatusKey: ProductStockStatus.onBackOrder.rawValue)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)

        // Action
        let tableViewModel = DefaultProductFormTableViewModel(product: model, actionsFactory: actionsFactory, currency: "")

        // Assert
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var inventoryViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .inventory(viewModel, _) = row {
                inventoryViewModel = viewModel
                break
            }
        }
        XCTAssertEqual(inventoryViewModel?.details, ProductStockStatus.onBackOrder.description)
    }

    func test_variable_product_inventory_row_has_no_details_when_stock_management_is_disabled_without_sku() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue,
                                          sku: "",
                                          manageStock: false,
                                          stockStatusKey: ProductStockStatus.onBackOrder.rawValue)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)

        // Action
        let tableViewModel = DefaultProductFormTableViewModel(product: model, actionsFactory: actionsFactory, currency: "")

        // Assert
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var inventoryViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .inventory(viewModel, _) = row {
                inventoryViewModel = viewModel
                break
            }
        }
        XCTAssertNil(inventoryViewModel?.details)
    }

    func test_variation_view_model_image_row_has_isVariation_true() {
        // Arrange
        let variation = ProductVariation.fake()
        let model = EditableProductVariationModel(productVariation: variation)
        let actionsFactory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Action
        let tableViewModel = DefaultProductFormTableViewModel(product: model, actionsFactory: actionsFactory, currency: "")

        // Assert
        guard case let .primaryFields(rows) = tableViewModel.sections[0] else {
            XCTFail("Unexpected section at index 0: \(tableViewModel.sections)")
            return
        }

        var isVariation: Bool?
        for row in rows {
            if case .images(_, _, let isVariationValue) = row {
                isVariation = isVariationValue
                break
            }
        }

        if let isVariation = isVariation {
            XCTAssertTrue(isVariation)
        } else {
            XCTFail("Cell not found")
        }
    }

    func test_product_view_model_image_row_has_isVariation_false() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue
        )
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)


        // Action
        let tableViewModel = DefaultProductFormTableViewModel(product: model, actionsFactory: actionsFactory, currency: "")

        // Assert
        guard case let .primaryFields(rows) = tableViewModel.sections[0] else {
            XCTFail("Unexpected section at index 0: \(tableViewModel.sections)")
            return
        }

        var isVariation: Bool?
        for row in rows {
            if case .images(_, _, let isVariationValue) = row {
                isVariation = isVariationValue
                break
            }
        }

        if let isVariation = isVariation {
            XCTAssertFalse(isVariation)
        } else {
            XCTFail("Cell not found")
        }
    }

    func test_shipping_settings_row_displays_localized_weight_and_dimensions() {
        // Given
        let dimensions = ProductDimensions(length: "2.9", width: "1.1", height: "113")
        let product = Product.fake()
            .copy(productTypeKey: ProductType.simple.rawValue,
                  weight: "1.6",
                  dimensions: dimensions)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let weightUnit = "kg"
        let dimensionUnit = "cm"
        let shippingValueLocalizer = DefaultShippingValueLocalizer(deviceLocale: Locale(identifier: "it_IT"))
        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "",
                                                              shippingValueLocalizer: shippingValueLocalizer,
                                                              weightUnit: weightUnit,
                                                              dimensionUnit: dimensionUnit)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var shippingViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .shipping(viewModel, _) = row {
                shippingViewModel = viewModel
                break
            }
        }

        XCTAssertEqual(shippingViewModel?.details, "Weight: 1,6\(weightUnit)\nDimensions: 2,9 x 1,1 x 113 \(dimensionUnit)")
    }

    func test_subscription_row_returns_expected_details_with_singular_format() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1", period: .month, periodInterval: "1", price: "5")
        let product = Product.fake().copy(productTypeKey: ProductType.subscription.rawValue, subscription: subscription)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var subscriptionViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .subscription(viewModel, _) = row {
                subscriptionViewModel = viewModel
                break
            }
        }
        let expectedDetails = [String.localizedStringWithFormat(Localization.priceFormat, "$5.00", "month"),
                               String.localizedStringWithFormat(Localization.expiryFormat, "1 month")].joined(separator: "\n")
        XCTAssertEqual(subscriptionViewModel?.details, expectedDetails)
    }

    func test_subscription_row_returns_expected_details_with_plural_format() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "4", period: .month, periodInterval: "2", price: "5")
        let product = Product.fake().copy(productTypeKey: ProductType.subscription.rawValue, subscription: subscription)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var subscriptionViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .subscription(viewModel, _) = row {
                subscriptionViewModel = viewModel
                break
            }
        }
        let expectedDetails = [String.localizedStringWithFormat(Localization.priceFormat, "$5.00", "2 months"),
                               String.localizedStringWithFormat(Localization.expiryFormat, "4 months")].joined(separator: "\n")
        XCTAssertEqual(subscriptionViewModel?.details, expectedDetails)
    }

    func test_subscription_row_returns_expected_details_for_no_price_or_expiry() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "0", period: .month, periodInterval: "2", price: "")
        let product = Product.fake().copy(productTypeKey: ProductType.subscription.rawValue, subscription: subscription)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var subscriptionViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .subscription(viewModel, _) = row {
                subscriptionViewModel = viewModel
                break
            }
        }
        let expectedDetails = String.localizedStringWithFormat(Localization.expiryFormat, Localization.neverExpire)
        XCTAssertEqual(subscriptionViewModel?.details, expectedDetails)
    }

    func test_quantity_rules_row_returns_expected_details_for_product_with_min_and_max_quantity() {
        // Given
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, minAllowedQuantity: "4", maxAllowedQuantity: "200", groupOfQuantity: "2")
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var quantityRulesViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .quantityRules(viewModel) = row {
                quantityRulesViewModel = viewModel
                break
            }
        }
        let expectedDetails = [String.localizedStringWithFormat(Localization.minQuantityFormat, "4"),
                               String.localizedStringWithFormat(Localization.maxQuantityFormat, "200")].joined(separator: "\n")
        XCTAssertEqual(quantityRulesViewModel?.details, expectedDetails)
    }

    func test_quantity_rules_row_returns_expected_details_for_product_with_min_and_groupOf_but_no_max_quantity() {
        // Given
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, minAllowedQuantity: "4", maxAllowedQuantity: "", groupOfQuantity: "2")
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var quantityRulesViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .quantityRules(viewModel) = row {
                quantityRulesViewModel = viewModel
                break
            }
        }
        let expectedDetails = [String.localizedStringWithFormat(Localization.minQuantityFormat, "4"),
                               String.localizedStringWithFormat(Localization.groupOfFormat, "2")].joined(separator: "\n")
        XCTAssertEqual(quantityRulesViewModel?.details, expectedDetails)
    }

    func test_quantity_rules_row_returns_expected_details_for_product_with_max_and_groupOf_but_no_min_quantity() {
        // Given
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, minAllowedQuantity: "", maxAllowedQuantity: "200", groupOfQuantity: "2")
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var quantityRulesViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .quantityRules(viewModel) = row {
                quantityRulesViewModel = viewModel
                break
            }
        }
        let expectedDetails = [String.localizedStringWithFormat(Localization.maxQuantityFormat, "200"),
                               String.localizedStringWithFormat(Localization.groupOfFormat, "2")].joined(separator: "\n")
        XCTAssertEqual(quantityRulesViewModel?.details, expectedDetails)
    }

    func test_quantity_rules_row_returns_expected_details_for_product_with_only_groupOf_quantity() {
        // Given
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, minAllowedQuantity: "", maxAllowedQuantity: "", groupOfQuantity: "2")
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model, formType: .edit)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let tableViewModel = DefaultProductFormTableViewModel(product: model,
                                                              actionsFactory: actionsFactory,
                                                              currency: "", currencyFormatter: currencyFormatter)

        // Then
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var quantityRulesViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .quantityRules(viewModel) = row {
                quantityRulesViewModel = viewModel
                break
            }
        }
        let expectedDetails = String.localizedStringWithFormat(Localization.groupOfFormat, "2")
        XCTAssertEqual(quantityRulesViewModel?.details, expectedDetails)
    }
}

private extension DefaultProductFormTableViewModelTests {
    enum Localization {
        static let priceFormat = NSLocalizedString("Regular price: %1$@ every %2$@",
                                                   comment: "Description of the subscription price for a product, with the price and billing frequency. " +
                                                   "Reads like: 'Regular price: $60.00 every 2 months'.")
        static let expiryFormat = NSLocalizedString("Expire after: %@",
                                                    comment: "Format of the expiry details on the Subscription row. Reads like: 'Expire after: 1 year'.")
        static let neverExpire = NSLocalizedString("Never expire", comment: "Display label when a subscription never expires.")
        static let minQuantityFormat = NSLocalizedString("Minimum quantity: %@",
                                                          comment: "Format of the Minimum Quantity setting (with a numeric quantity) on the Quantity Rules row")
        static let maxQuantityFormat = NSLocalizedString("Maximum quantity: %@",
                                                       comment: "Format of the Maximum Quantity setting (with a numeric quantity) on the Quantity Rules row")
        static let groupOfFormat = NSLocalizedString("Group of: %@",
                                                       comment: "Format of the Group Of setting (with a numeric quantity) on the Quantity Rules row")
    }
}
