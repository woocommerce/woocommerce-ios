import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductDownloadSettingsViewModelTests: XCTestCase {

    // MARK: - Initialization

    func test_readonly_values_are_as_expected_after_initializing_download_settings() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Assert
        XCTAssertEqual(viewModel.downloadLimit, 1)
        XCTAssertEqual(viewModel.downloadExpiry, 1)
    }

    func test_section_and_row_values_are_as_expected_after_initializing_download_settings() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Act
        let expectedSections: [ProductDownloadSettingsViewController.Section] = [
            .init(footer: ProductDownloadSettingsViewModel.Localization.downloadLimitFooter, rows: [ProductDownloadSettingsViewController.Row.limit]),
            .init(footer: ProductDownloadSettingsViewModel.Localization.downloadExpiryFooter, rows: [ProductDownloadSettingsViewController.Row.expiry])
        ]

        // Assert
        XCTAssertEqual(viewModel.sections, expectedSections)
    }

    // MARK: - `handleDownloadLimitChange`

    func test_handling_empty_downloadLimit_updates_with_default_value() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)
        let defaultLimit: Int64 = -1

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleDownloadLimitChange("") { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.downloadLimit, defaultLimit)
    }

    func test_handling_non_empty_downloadLimit_updates_with_success() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)
        let expectedLimit: Int64 = 100

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleDownloadLimitChange("100") { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.downloadLimit, expectedLimit)
    }

    func test_handling_invalid_downloadLimit_updates_with_default_value() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)
        let defaultLimit: Int64 = -2

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleDownloadLimitChange("-100") { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.downloadLimit, defaultLimit)
    }

    // MARK: - `handleDownloadExpiryChange`

    func test_handling_empty_downloadExpiry_updates_with_default_value() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)
        let defaultExpiry: Int64 = -1

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleDownloadExpiryChange("") { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.downloadExpiry, defaultExpiry)
    }

    func test_handling_non_empty_downloadExpiry_updates_with_success() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)
        let expectedExpiry: Int64 = 100

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleDownloadExpiryChange("100") { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.downloadExpiry, expectedExpiry)
    }

    func test_handling_invalid_downloadExpiry_updates_with_default_value() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)
        let defaultExpiry: Int64 = -2

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleDownloadExpiryChange("-100") { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.downloadExpiry, defaultExpiry)
    }

    // MARK: - `hasUnsavedChanges`

    func test_viewModel_has_unsaved_changes_after_updating_validD_downloadLimit() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Act
        let expected = "100"
        viewModel.handleDownloadLimitChange(expected) { _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func test_viewModel_has_unsaved_changes_with_default_value_after_updating_invalid_downloadLimit() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Act
        let expected = "-100"
        viewModel.handleDownloadLimitChange(expected) { _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_unsaved_changes_after_updating_valid_downloadExpiry() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Act
        let expected = "100"
        viewModel.handleDownloadExpiryChange(expected) { _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func test_viewModel_has_unsaved_changes_with_default_value_after_updating_invalid_downloadExpiry() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Act
        let expected = "-100"
        viewModel.handleDownloadExpiryChange(expected) { _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_no_unsaved_changes_after_updating_with_the_original_values() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadSettingsViewModel(product: model)

        // Act
        viewModel.handleDownloadLimitChange("1") { _ in }
        viewModel.handleDownloadExpiryChange("1") { _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
