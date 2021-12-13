import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductShippingSettingsViewModelTests: XCTestCase {
    typealias Section = ProductShippingSettingsViewController.Section

    // MARK: - Initialization

    func test_readonly_shipping_values_are_as_expected_after_initialization() {
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

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.weight, .length, .width, .height]),
            .init(rows: [.shippingClass])
        ]
        XCTAssertEqual(viewModel.sections, expectedSections)
        XCTAssertEqual(viewModel.product as? EditableProductModel, model)
        XCTAssertEqual(viewModel.weight, "1.6")
        XCTAssertEqual(viewModel.length, dimensions.length)
        XCTAssertEqual(viewModel.width, dimensions.width)
        XCTAssertEqual(viewModel.height, dimensions.height)
        XCTAssertNil(viewModel.shippingClass)
    }

    // MARK: - `completeUpdating`

    func test_shipping_values_remain_the_same_after_completing_update_before_shipping_class_API_sync() {
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
        waitForExpectation { expectation in
            viewModel.completeUpdating { (weight, dimensions, shippingClass, shippingClassID, hasUnsavedChanges) in
                // Assert
                XCTAssertEqual(weight, product.weight)
                XCTAssertEqual(dimensions, product.dimensions)
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
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        let retrievedShippingClass = ProductShippingClass(count: 0, descriptionHTML: nil, name: "60 Days", shippingClassID: 2, siteID: 0, slug: "90-day")
        viewModel.onShippingClassRetrieved(shippingClass: retrievedShippingClass)
        waitForExpectation { expectation in
            viewModel.completeUpdating { (weight, dimensions, shippingClass, shippingClassID, hasUnsavedChanges) in
                // Assert
                XCTAssertEqual(weight, product.weight)
                XCTAssertEqual(dimensions, product.dimensions)
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
                  shippingClassID: 2)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)
        viewModel.handleWeightChange("-1.2")
        viewModel.handleWidthChange("3.2")
        viewModel.handleHeightChange("9.888")
        viewModel.handleLengthChange("")
        viewModel.handleShippingClassChange(nil)
        waitForExpectation { expectation in
            viewModel.completeUpdating { (weight, dimensions, shippingClass, shippingClassID, hasUnsavedChanges) in
                // Assert
                XCTAssertEqual(weight, "-1.2")
                XCTAssertEqual(dimensions, ProductDimensions(length: "", width: "3.2", height: "9.888"))
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
}
