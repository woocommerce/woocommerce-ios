import XCTest
@testable import WooCommerce

final class ProductCreationAIStartingInfoViewModelTests: XCTestCase {
    private let siteID: Int64 = 123
    private let sampleImage = MediaPickerImage(image: .addImage, source: .media(media: .fake()))

    func test_imageState_empty_initially() {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        // Then
        XCTAssertEqual(sut.imageState, .empty)
    }

    func test_it_shows_media_picker_source_sheet_upon_tapping_read_text_button() {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        // When
        sut.didTapReadTextFromPhoto()

        // Then
        XCTAssertTrue(sut.isShowingMediaPickerSourceSheet)
    }

    func test_it_shows_media_picker_source_sheet_upon_tapping_replace_photo_button() {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        // When
        sut.didTapReplacePhoto()

        // Then
        XCTAssertTrue(sut.isShowingMediaPickerSourceSheet)
    }

    func test_it_shows_view_package_photo_sheet_upon_tapping_view_photo_button() {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        // When
        sut.didTapViewPhoto()

        // Then
        XCTAssertTrue(sut.isShowingViewPhotoSheet)
    }

    func test_it_sets_imageState_upon_selecting_image() async {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }

        // When
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertEqual(sut.imageState, .success(sampleImage))
    }

    func test_it_sets_imageState_to_old_value_if_image_not_selected() async {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }
        await sut.selectImage(from: .siteMediaLibrary)

        // When
        sut.onPickPackagePhoto = { _ in
            nil
        }
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertEqual(sut.imageState, .success(sampleImage))
    }

    func test_it_removes_selected_image_upon_tapping_remove_photo_button() async {
        // Given
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }
        await sut.selectImage(from: .siteMediaLibrary)

        // When
        sut.didTapRemovePhoto()

        // Then
        XCTAssertEqual(sut.imageState, .empty)
    }

    func test_it_populates_detected_texts() async {
        // Given
        let imageTextScanner = MockImageTextScanner(result: .success(["test", "product", "package"]))
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID,
                                                         imageTextScanner: imageTextScanner)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }

        // When
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertEqual(sut.features, "test product package")
    }

    func test_it_preserves_previously_detected_text_when_text_detection_fails() async {
        // Given
        let imageTextScanner = MockImageTextScanner(result: .success(["test", "product", "package"]))
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID,
                                                         imageTextScanner: imageTextScanner)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }
        await sut.selectImage(from: .siteMediaLibrary)
        XCTAssertEqual(sut.features, "test product package")

        // When
        let error = NSError(domain: "test", code: 10000)
        imageTextScanner.result = .failure(error)
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertEqual(sut.features, "test product package")
    }

    func test_it_shows_text_detection_error_when_text_detection_fails() async {
        // Given
        let error = NSError(domain: "test", code: 10000)
        let imageTextScanner = MockImageTextScanner(result: .failure(error))
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID,
                                                         imageTextScanner: imageTextScanner)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }

        // When
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertEqual(sut.textDetectionErrorMessage,
                       ProductCreationAIStartingInfoViewModel.Localization.textDetectionFailed)
    }

    func test_it_shows_text_detection_error_when_no_text_detected() async {
        // Given
        let imageTextScanner = MockImageTextScanner(result: .success([]))
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID,
                                                         imageTextScanner: imageTextScanner)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }

        // When
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertEqual(sut.textDetectionErrorMessage,
                       ProductCreationAIStartingInfoViewModel.Localization.noTextDetected)
    }

    func test_it_resets_text_detection_error_when_new_image_with_text_is_loaded_again() async {
        // Given
        let imageTextScanner = MockImageTextScanner(result: .success([]))
        let sut = ProductCreationAIStartingInfoViewModel(siteID: siteID,
                                                         imageTextScanner: imageTextScanner)

        sut.onPickPackagePhoto = { _ in
            self.sampleImage
        }
        await sut.selectImage(from: .siteMediaLibrary)
        XCTAssertEqual(sut.textDetectionErrorMessage,
                       ProductCreationAIStartingInfoViewModel.Localization.noTextDetected)

        // When
        imageTextScanner.result = .success(["test"])
        await sut.selectImage(from: .siteMediaLibrary)

        // Then
        XCTAssertNil(sut.textDetectionErrorMessage)
    }
}
