import XCTest
import Fakes
@testable import WooCommerce
@testable import Yosemite

final class ProductDownloadFileViewModelTests: XCTestCase {

    // MARK: - Initialization

    func test_readonly_values_are_as_expected_after_initializing_a_downloadableFile_in_edit_mode() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)

        // Assert
        XCTAssertEqual(viewModel.fileID, "1f9c11f99ceba63d4403c03bd5391b11")
        XCTAssertEqual(viewModel.fileName, "Song #1")
        XCTAssertEqual(viewModel.fileURL, "https://example.com/woo-single-1.ogg")
        XCTAssertEqual(viewModel.formType, ProductDownloadFileViewController.FormType.edit)
    }

    func test_readonly_values_are_as_expected_after_initializing_a_downloadableFile_in_add_mode() {

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: nil, downloadFileIndex: nil, formType: .add)

        // Assert
        XCTAssertNil(viewModel.fileID)
        XCTAssertNil(viewModel.fileName)
        XCTAssertNil(viewModel.fileURL)
        XCTAssertEqual(viewModel.formType, ProductDownloadFileViewController.FormType.add)
    }

    func test_section_and_row_values_are_as_expected_after_initializing_a_downloadableFile_in_edit_mode() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)


        // Act
        let expectedSections: [ProductDownloadFileViewController.Section] = [
            .init(footer: ProductDownloadFileViewModel.Strings.urlFooter, rows: [ProductDownloadFileViewController.Row.url]),
            .init(footer: ProductDownloadFileViewModel.Strings.fileNameFooter, rows: [ProductDownloadFileViewController.Row.name])
        ]

        // Assert
        XCTAssertEqual(viewModel.sections, expectedSections)
    }

    // MARK: - `handleFileNameChange`

    func test_handling_a_same_downloadable_fileName_updates_with_error_on_edit_mode() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expectedName = "Song #1"

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileNameChange(expectedName) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.fileName, expectedName)
    }

    func test_handling_an_empty_downloadable_fileName_updates_with_error_on_edit_mode() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expectedName = ""

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileNameChange(expectedName) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.fileName, expectedName)
    }

    func test_handling_a_valid_downloadable_fileName_updates_with_success_on_edit_mode() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expectedName = "Song #10"

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileNameChange(expectedName) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.fileName, expectedName)
    }

    // MARK: - `handleFileUrlChange`

    func test_handling_a_same_downloadable_fileURL_updates_with_error_on_edit_mode() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expectedUrl = "https://example.com/woo-single-1.ogg"

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedUrl) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.fileURL, expectedUrl)
    }

    func test_handling_a_valid_downloadable_fileURL_updates_with_success_on_add_mode() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .add)
        let expectedUrl = "https://example.com/woo-single-1.ogg"

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedUrl) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.fileURL, expectedUrl)
    }

    func test_handling_an_empty_downloadable_fileURL_updates_with_error_on_edit_mode() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expectedURL = ""

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedURL) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.fileURL, expectedURL)
    }

    func test_handling_a_valid_downloadable_fileURL_updates_with_success_on_edit_mode() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expectedUrl = "https://example.com/single.jpeg"

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedUrl) { isValid in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(viewModel.fileURL, expectedUrl)
    }

    // MARK: - `hasUnsavedChanges`

    func test_viewModel_has_unsaved_changes_after_updating_valid_downloadFileName() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expected = "single image"
        viewModel.handleFileNameChange(expected) { _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func test_viewModel_has_no_unsaved_changes_after_updating_invalid_downloadFileName() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expected = ""
        viewModel.handleFileNameChange(expected) { _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_unsaved_changes_after_updating_valid_downloadFileUrl() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expected = "https://example.com/single.jpeg"
        viewModel.handleFileUrlChange(expected) { _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func test_viewModel_has_no_unsaved_changes_after_updating_invalid_downloadFileUrl() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        let expected = ""
        viewModel.handleFileUrlChange(expected) { _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_no_unsaved_changes_after_updating_with_the_original_values() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productDownload = model.downloadableFiles.first

        // Act
        let viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: 0, formType: .edit)
        viewModel.handleFileNameChange("Song #1") { _ in }
        viewModel.handleFileUrlChange("https://example.com/woo-single-1.ogg") { _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
