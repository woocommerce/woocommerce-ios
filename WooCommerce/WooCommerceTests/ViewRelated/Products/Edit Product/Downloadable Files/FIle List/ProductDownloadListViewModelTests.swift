import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductDownloadListViewModelTests: XCTestCase {

    // MARK: - Initialization

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductWithNonEmptyDownloadableFiles() throws {
        // Arrange
        let product = MockProduct().product(downloadable: true)
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
    }

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductWithEmptyDownloadableFiles() {
        // Arrange
        let product = MockProduct().product(downloadable: false)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)

        // Assert
        XCTAssertEqual(viewModel.count(), 0)
        XCTAssertEqual(viewModel.downloadLimit, -1)
        XCTAssertEqual(viewModel.downloadExpiry, -1)
    }

    // MARK: - `handleDownloadableFilesChange`

    func testHandlingADuplicateDownloadableFilesUpdatesWithError() {

    }

    func testHandlingAValidDownloadableFilesUpdatesWithSuccess() {

    }

    func testHandlingTheOriginalDownloadableFilesIsAlwaysValidAndUnique() {

    }

    func testHandlingAValidDownloadableFilesAddsWithSuccess() {

    }

    func testHandlingAValidExistingDownloadableFileRemovesWithSuccess() {

    }

    // MARK: - `handleDownloadLimitChange`

    func testHandlingAValidDownloadLimitUpdatesWithSuccess() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadLimitChange(5)

        // Assert
        XCTAssertEqual(viewModel.downloadLimit, 5)
    }

    // MARK: - `handleDownloadExpiryChange`

    func testHandlingAValidDownloadExpiryUpdatesWithSuccess() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadExpiryChange(5)

        // Assert
        XCTAssertEqual(viewModel.downloadExpiry, 5)
    }

    // MARK: - `hasUnsavedChanges`

    func testViewModelHasUnsavedChangesAfterUpdatingDownloadFileLimit() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadLimitChange(5)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func testViewModelHasUnsavedChangesAfterUpdatingDownloadFileExpiry() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadExpiryChange(5)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasUnsavedChangesAfterUpdatingDownloadFilesOrder() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        guard let firstFile = viewModel.remove(at: 0) else {
            XCTFail()
            return
        }
        viewModel.insert(firstFile, at: 1)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasUnsavedChangesAfterRemovingDownloadFileIndividually() {

    }

    func testViewModelHasUnsavedChangesAfterAddingDownloadFileIndividually() {

    }

    func testViewModelHasUnsavedChangesAfterUpdatingSingleDownloadFileIndividually() {

    }

    func testViewModelHasNoUnsavedChangesAfterUpdatingWithTheOriginalValues() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadListViewModel(product: model)
        viewModel.handleDownloadableFilesChange(MockProduct().sampleDownloads())

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
