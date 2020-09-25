import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductDownloadFileViewModelTests: XCTestCase {

    // MARK: - Initialization

    func testReadonlyValuesAreAsExpectedAfterInitializingADownloadableFileInEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)

        // Assert
        XCTAssertEqual(viewModel.fileID, "1f9c11f99ceba63d4403c03bd5391b11")
        XCTAssertEqual(viewModel.fileName, "Song #1")
        XCTAssertEqual(viewModel.fileURL, "https://example.com/woo-single-1.ogg")
        XCTAssertEqual(viewModel.formType, ProductDownloadFileViewController.FormType.edit)
    }

    func testReadonlyValuesAreAsExpectedAfterInitializingADownloadableFileInAddMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, formType: .add)

        // Assert
        XCTAssertNil(viewModel.fileID)
        XCTAssertNil(viewModel.fileName)
        XCTAssertNil(viewModel.fileURL)
        XCTAssertEqual(viewModel.formType, ProductDownloadFileViewController.FormType.add)
    }

    func testSectionAndRowValuesAreAsExpectedAfterInitializingADownloadableFileInAddMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)

        // Act
        let expectedSections: [ProductDownloadFileViewController.Section] = [
            .init(footer: ProductDownloadFileViewModel.Strings.urlFooter, rows: [ProductDownloadFileViewController.Row.url]),
            .init(footer: ProductDownloadFileViewModel.Strings.fileNameFooter, rows: [ProductDownloadFileViewController.Row.name])
        ]

        // Assert
        XCTAssertEqual(viewModel.sections, expectedSections)
    }

    // MARK: - `handleFileNameChange`

    func testHandlingASameDownloadableFileNameUpdatesWithErrorOnEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expectedName = "Song #1"

        // Act
        var isValidResult: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleFileNameChange(expectedName) { (isValid, shouldBringUpKeyboardValue) in
                isValidResult = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(shouldBringUpKeyboard, true)
        XCTAssertEqual(viewModel.fileName, expectedName)
    }

    func testHandlingAnEmptyDownloadableFileNameUpdatesWithErrorOnEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expectedName = ""

        // Act
        var isValidResult: Bool?
        waitForExpectation { exp in
            viewModel.handleFileNameChange(expectedName) { (isValid, _) in
                isValidResult = isValid
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(viewModel.fileName, expectedName)
    }

    func testHandlingAValidDownloadableFileNameUpdatesWithSuccessOnEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expectedName = "Song #10"

        // Act
        var isValidResult: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleFileNameChange(expectedName) { (isValid, shouldBringUpKeyboardValue) in
                isValidResult = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(shouldBringUpKeyboard, false)
        XCTAssertEqual(viewModel.fileName, expectedName)
    }

    // MARK: - `handleFileUrlChange`

    func testHandlingASameDownloadableFileURLUpdatesWithErrorOnEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expectedUrl = "https://example.com/woo-single-1.ogg"

        // Act
        var isValidResult: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedUrl) { (isValid, shouldBringUpKeyboardValue) in
                isValidResult = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(shouldBringUpKeyboard, true)
        XCTAssertEqual(viewModel.fileURL, expectedUrl)
    }

    func testHandlingASameDownloadableFileURLUpdatesWithErrorOnAddMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .add)
        let expectedUrl = "https://example.com/woo-single-1.ogg"

        // Act
        var isValidResult: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedUrl) { (isValid, shouldBringUpKeyboardValue) in
                isValidResult = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(shouldBringUpKeyboard, true)
        XCTAssertEqual(viewModel.fileURL, expectedUrl)
    }

    func testHandlingAnEmptyDownloadableFileURLUpdatesWithErrorOnEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expectedURL = ""

        // Act
        var isValidResult: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedURL) { (isValid, shouldBringUpKeyboardValue) in
                isValidResult = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, false)
        XCTAssertEqual(shouldBringUpKeyboard, false)
        XCTAssertEqual(viewModel.fileURL, expectedURL)
    }

    func testHandlingAValidDownloadableFileURLUpdatesWithSuccessOnEditMode() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expectedUrl = "https://example.com/single.jpeg"

        // Act
        var isValidResult: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleFileUrlChange(expectedUrl) { (isValid, shouldBringUpKeyboardValue) in
                isValidResult = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isValidResult, true)
        XCTAssertEqual(shouldBringUpKeyboard, false)
        XCTAssertEqual(viewModel.fileURL, expectedUrl)
    }

    // MARK: - `hasUnsavedChanges`

    func testViewModelHasUnsavedChangesAfterUpdatingValidDownloadFileName() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expected = "single image"
        viewModel.handleFileNameChange(expected) { _, _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func testViewModelHasNoUnsavedChangesAfterUpdatingInvalidDownloadFileName() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expected = ""
        viewModel.handleFileNameChange(expected) { _, _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasUnsavedChangesAfterUpdatingValidDownloadFileUrl() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expected = "https://example.com/single.jpeg"
        viewModel.handleFileUrlChange(expected) { _, _ in }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())

    }

    func testViewModelHasNoUnsavedChangesAfterUpdatingInvalidDownloadFileUrl() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        let expected = ""
        viewModel.handleFileUrlChange(expected) { _, _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasNoUnsavedChangesAfterUpdatingWithTheOriginalValues() {
        // Arrange
        let product = MockProduct().product(downloadable: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductDownloadFileViewModel(product: model, downloadFileIndex: 0, formType: .edit)
        viewModel.handleFileNameChange("Song #1") { _, _ in }
        viewModel.handleFileUrlChange("https://example.com/woo-single-1.ogg") { _, _ in }

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
