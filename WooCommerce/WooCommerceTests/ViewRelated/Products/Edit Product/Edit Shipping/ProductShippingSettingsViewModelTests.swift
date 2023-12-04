import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductShippingSettingsViewModelTests: XCTestCase {
    typealias Section = ProductShippingSettingsViewController.Section

    // MARK: - Initialization

    func test_readonly_shipping_values_are_as_expected_based_on_locale_after_initialization() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(productTypeKey: "subscription",
                  weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2)
        let model = EditableProductModel(product: product)
        let shippingValueLocalizer = DefaultShippingValueLocalizer(deviceLocale: Locale(identifier: "it_IT"))

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model,
                                                         shippingValueLocalizer: shippingValueLocalizer)

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.weight, .length, .width, .height]),
            .init(rows: [.shippingClass])
        ]
        XCTAssertEqual(viewModel.sections, expectedSections)
        XCTAssertEqual(viewModel.product as? EditableProductModel, model)
        XCTAssertEqual(viewModel.localizedWeight, "1,6")
        XCTAssertEqual(viewModel.localizedLength, "2,9")
        XCTAssertEqual(viewModel.localizedWidth, "")
        XCTAssertEqual(viewModel.localizedHeight, "1116")
        XCTAssertNil(viewModel.shippingClass)
    }

    // MARK: - `completeUpdating`

    func test_shipping_values_remain_the_same_after_completing_update_before_shipping_class_API_sync() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(productTypeKey: "subscription",
                  weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(trialLength: "0",
                                             oneTimeShipping: true,
                                             paymentSyncDate: "0"))
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        waitForExpectation { expectation in
            viewModel.completeUpdating { (weight, dimensions, oneTimeShipping, shippingClass, shippingClassID, hasUnsavedChanges) in
                // Assert
                XCTAssertEqual(weight, product.weight)
                XCTAssertEqual(dimensions, product.dimensions)
                XCTAssertEqual(oneTimeShipping, product.subscription?.oneTimeShipping)
                XCTAssertEqual(shippingClass, product.shippingClass)
                XCTAssertEqual(shippingClassID, product.shippingClassID)
                XCTAssertFalse(hasUnsavedChanges)
                expectation.fulfill()
            }
        }
    }

    func test_shipping_values_remain_the_same_after_completing_update_following_shipping_class_API_sync_with_a_different_slug() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(productTypeKey: "subscription",
                  weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(trialLength: "0",
                                             oneTimeShipping: true,
                                             paymentSyncDate: "0"))
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        let retrievedShippingClass = ProductShippingClass(count: 0, descriptionHTML: nil, name: "60 Days", shippingClassID: 2, siteID: 0, slug: "90-day")
        viewModel.onShippingClassRetrieved(shippingClass: retrievedShippingClass)
        waitForExpectation { expectation in
            viewModel.completeUpdating { (weight, dimensions, oneTimeShipping, shippingClass, shippingClassID, hasUnsavedChanges) in
                // Assert
                XCTAssertEqual(weight, product.weight)
                XCTAssertEqual(dimensions, product.dimensions)
                XCTAssertEqual(oneTimeShipping, product.subscription?.oneTimeShipping)
                XCTAssertEqual(shippingClass, product.shippingClass)
                XCTAssertEqual(shippingClassID, product.shippingClassID)
                XCTAssertFalse(hasUnsavedChanges)
                expectation.fulfill()
            }
        }
    }

    func test_shipping_values_are_updated_after_completing_update() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(oneTimeShipping: false))
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        viewModel.handleWeightChange("-1.2")
        viewModel.handleWidthChange("3.2")
        viewModel.handleHeightChange("9.888")
        viewModel.handleLengthChange("")
        viewModel.handleOneTimeShippingChange(true)
        viewModel.handleShippingClassChange(nil)
        waitForExpectation { expectation in
            viewModel.completeUpdating { (weight, dimensions, oneTimeShipping, shippingClass, shippingClassID, hasUnsavedChanges) in
                // Assert
                XCTAssertEqual(weight, "-1.2")
                XCTAssertEqual(dimensions, ProductDimensions(length: "", width: "3.2", height: "9.888"))
                XCTAssertEqual(oneTimeShipping, true)
                XCTAssertEqual(shippingClass, nil)
                XCTAssertEqual(shippingClassID, 0)
                XCTAssertTrue(hasUnsavedChanges)
                expectation.fulfill()
            }
        }
    }

    // MARK: `hasUnsavedChanges`

    func test_shipping_class_API_sync_with_a_different_slug_has_no_unsaved_changes() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        let retrievedShippingClass = ProductShippingClass(count: 0, descriptionHTML: nil, name: "60 Days", shippingClassID: 2, siteID: 0, slug: "90-day")
        viewModel.onShippingClassRetrieved(shippingClass: retrievedShippingClass)
        let hasUnsavedChanges = viewModel.hasUnsavedChanges()

        // Assert
        XCTAssertFalse(hasUnsavedChanges)
    }

    func test_updating_with_the_same_values_has_no_unsaved_changes() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        viewModel.handleWeightChange("1.6")
        viewModel.handleWidthChange("")
        viewModel.handleHeightChange("1116")
        viewModel.handleLengthChange("2.9")
        let retrievedShippingClass = ProductShippingClass(count: 0, descriptionHTML: nil, name: "60 Days", shippingClassID: 2, siteID: 0, slug: "90-day")
        viewModel.onShippingClassRetrieved(shippingClass: retrievedShippingClass)
        viewModel.handleShippingClassChange(retrievedShippingClass)
        let hasUnsavedChanges = viewModel.hasUnsavedChanges()

        // Assert
        XCTAssertFalse(hasUnsavedChanges)
    }

    func test_updating_with_different_values_has_unsaved_changes() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        viewModel.handleWeightChange("-1.2")
        viewModel.handleWidthChange("3.2")
        viewModel.handleHeightChange("9.888")
        viewModel.handleLengthChange("")
        viewModel.handleShippingClassChange(nil)
        let hasUnsavedChanges = viewModel.hasUnsavedChanges()

        // Assert
        XCTAssertTrue(hasUnsavedChanges)
    }

    // MARK: `oneTimeShipping`

    func test_updating_with_the_same_oneTimeShipping_value_has_no_unsaved_changes() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(oneTimeShipping: true))
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        viewModel.handleOneTimeShippingChange(true)
        let hasUnsavedChanges = viewModel.hasUnsavedChanges()

        // Assert
        XCTAssertFalse(hasUnsavedChanges)
    }

    func test_updating_with_different_oneTimeShipping_value_has_unsaved_changes() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(oneTimeShipping: true))
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        viewModel.handleOneTimeShippingChange(false)
        let hasUnsavedChanges = viewModel.hasUnsavedChanges()

        // Assert
        XCTAssertTrue(hasUnsavedChanges)
    }

    func test_oneTimeShipping_row_is_added_for_product() {
        // Given
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(oneTimeShipping: true))
        let model = EditableProductModel(product: product)
        let viewModel = ProductShippingSettingsViewModel(product: model)

        // Then
        XCTAssertTrue(viewModel.sections.flatMap({ $0.rows }).contains(where: { $0 == .oneTimeShipping}))
    }

    func test_oneTimeShipping_row_is_not_added_for_product_variation() {
        // Given
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = ProductVariation.fake()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(oneTimeShipping: true))
        let model = EditableProductVariationModel(productVariation: product)
        let viewModel = ProductShippingSettingsViewModel(product: model)

        // Then
        XCTAssertFalse(viewModel.sections.flatMap({ $0.rows }).contains(where: { $0 == .oneTimeShipping}))
    }

    // MARK: `supportsOneTimeShipping`

    func test_supportsOneTimeShipping_is_true_when_no_free_trial_or_payment_sync_date_available() {
        // Given
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(productTypeKey: "subscription",
                  weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(trialLength: "0",
                                             paymentSyncDate: "0"))
        let model = EditableProductModel(product: product)
        let viewModel = ProductShippingSettingsViewModel(product: model)

        // Then
        XCTAssertTrue(viewModel.supportsOneTimeShipping)
    }

    func test_supportsOneTimeShipping_is_false_when_free_trial_available() {
        // Given
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(productTypeKey: "subscription",
                  weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(trialLength: "1",
                                             paymentSyncDate: "0"))
        let model = EditableProductModel(product: product)
        let viewModel = ProductShippingSettingsViewModel(product: model)

        // Then
        XCTAssertFalse(viewModel.supportsOneTimeShipping)
    }

    func test_supportsOneTimeShipping_is_false_when_payment_sync_date_available() {
        // Given
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let product = Product.fake()
            .copy(productTypeKey: "subscription",
                  weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2,
                  subscription: .fake().copy(trialLength: "0",
                                             paymentSyncDate: "10"))
        let model = EditableProductModel(product: product)
        let viewModel = ProductShippingSettingsViewModel(product: model)

        // Then
        XCTAssertFalse(viewModel.supportsOneTimeShipping)
    }
}
