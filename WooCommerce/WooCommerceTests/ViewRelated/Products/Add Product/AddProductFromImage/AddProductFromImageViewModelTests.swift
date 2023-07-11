import TestKit
import XCTest

@testable import WooCommerce

@MainActor
final class AddProductFromImageViewModelTests: XCTestCase {
    func test_initial_name_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.name, "")
    }

    func test_initial_description_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.description, "")
    }

    // MARK: - `addImage`

    func test_imageState_is_reverted_to_empty_when_addImage_returns_nil() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let viewModel = AddProductFromImageViewModel(onAddImage: { _ in
            nil
        })
        XCTAssertEqual(viewModel.imageState, .empty)

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then
        waitUntil {
            viewModel.imageState == .empty
        }
    }

    func test_imageState_is_reverted_to_success_when_addImage_returns_image_then_nil() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        var imageToReturn: MediaPickerImage? = image
        let viewModel = AddProductFromImageViewModel(onAddImage: { _ in
            imageToReturn
        })
        XCTAssertEqual(viewModel.imageState, .empty)

        // When adding an image returns an image
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then imageState becomes success
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // When adding an image returns nil
        imageToReturn = nil
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then imageState stays success
        waitUntil {
            viewModel.imageState == .success(image)
        }
    }
}
