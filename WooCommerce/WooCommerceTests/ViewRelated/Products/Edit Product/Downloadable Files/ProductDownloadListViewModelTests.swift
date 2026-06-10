import XCTest
import Fakes
@testable import WooCommerce
@testable import Yosemite

final class ProductDownloadListViewModelTests: XCTestCase {

    // MARK: - Initialization

    func test_readonly_values_are_as_expected_after_initializing_a_product_with_non_empty_downloadable_files() throws {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)

        // Assert
        XCTAssertEqual(viewModel.count(), 3)
        XCTAssertEqual(viewModel.downloadLimit, 1)
        XCTAssertEqual(viewModel.downloadExpiry, 1)
        let file = try XCTUnwrap(viewModel.item(at: 0))
        XCTAssertEqual(file.downloadableFile.downloadID, "1f9c11f99ceba63d4403c03bd5391b11")
        XCTAssertEqual(file.downloadableFile.name, "Song #1")
        XCTAssertEqual(file.downloadableFile.fileURL, "https://example.com/woo-single-1.ogg")

        let expectedBottomSheetActions: [DownloadableFileSource] = [.deviceMedia, .deviceDocument, .wordPressMediaLibrary, .fileURL]
        XCTAssertEqual(viewModel.bottomSheetActions.count, 4)
        XCTAssertEqual(viewModel.bottomSheetActions, expectedBottomSheetActions)
    }

    func test_readonly_values_are_as_expected_after_initializing_a_product_with_empty_downloadable_files() {
        // Arrange
        let product = Product.fake().copy(downloadable: false, downloadLimit: -1, downloadExpiry: -1)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)

        // Assert
        XCTAssertEqual(viewModel.count(), 0)
        XCTAssertEqual(viewModel.downloadLimit, -1)
        XCTAssertEqual(viewModel.downloadExpiry, -1)

        let expectedBottomSheetActions: [DownloadableFileSource] = [.deviceMedia, .deviceDocument, .wordPressMediaLibrary, .fileURL]
        XCTAssertEqual(viewModel.bottomSheetActions.count, 4)
        XCTAssertEqual(viewModel.bottomSheetActions, expectedBottomSheetActions)
    }

    // TODO: - test cases for `handleDownloadableFilesChange`

    // MARK: - `handleDownloadLimitChange`

    func test_handling_a_valid_downloadLimit_updates_with_success() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadLimitChange(5)

        // Assert
        XCTAssertEqual(viewModel.downloadLimit, 5)
    }

    // MARK: - `handleDownloadExpiryChange`

    func test_handling_a_valid_downloadExpiry_updates_with_success() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadExpiryChange(5)

        // Assert
        XCTAssertEqual(viewModel.downloadExpiry, 5)
    }

    // MARK: - `hasUnsavedChanges`

    func test_viewModel_has_unsaved_changes_after_updating_downloadLimit() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadLimitChange(5)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_unsaved_changes_after_updating_downloadExpiry() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadExpiryChange(5)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_unsaved_changes_after_updating_downloadableFiles_order() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        guard let firstFile = viewModel.remove(at: 0) else {
            XCTFail("Downloadable file does not exist")
            return
        }
        viewModel.insert(firstFile, at: 1)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_move_when_moving_first_file_to_end_then_reorders_without_duplicates() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadListViewModel(product: model)

        // Act
        viewModel.move(from: 0, to: 2)

        // Assert
        XCTAssertEqual(viewModel.downloadableFiles.map { $0.downloadableFile.name }, ["Song #2", "Song #3", "Song #1"])
    }

    func test_move_when_moving_last_file_to_start_then_reorders_without_duplicates() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadListViewModel(product: model)

        // Act
        viewModel.move(from: 2, to: 0)

        // Assert
        XCTAssertEqual(viewModel.downloadableFiles.map { $0.downloadableFile.name }, ["Song #3", "Song #1", "Song #2"])
    }

    func test_insert_when_reinserting_removed_file_at_original_end_index_then_does_not_crash() throws {
        // Given
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadListViewModel(product: model)
        let originalEndIndex = viewModel.count()
        let removedFile = try XCTUnwrap(viewModel.remove(at: 0))

        // When
        viewModel.insert(removedFile, at: originalEndIndex)

        // Then
        XCTAssertTrue(true)
    }

    func test_viewModel_has_unsaved_changes_after_updating_with_the_original_values() {
        // Arrange
        let product = Fakes.ProductFactory.productWithDownloadableFiles()
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadableFilesChange(product.downloads)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
