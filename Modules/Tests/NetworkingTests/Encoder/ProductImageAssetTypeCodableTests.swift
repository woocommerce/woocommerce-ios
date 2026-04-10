import XCTest
import Photos
@testable import Networking
@testable import NetworkingCore

final class ProductImageAssetTypeCodableTests: XCTestCase {

    func test_uiImage_encodes_and_decodes_correctly() throws {
        // Given
        let assetType = ProductImageAssetType.uiImage(
            image: UIImage.checkmark,
            filename: "test_image.png",
            altText: "Test Alt Text"
        )

        // When
        let data = try JSONEncoder().encode(assetType)
        let decodedAssetType = try JSONDecoder().decode(ProductImageAssetType.self, from: data)

        // Then
        if case let .uiImage(decodedImage, decodedFilename, decodedAltText) = decodedAssetType {
            XCTAssertNotNil(decodedImage.pngData(), "Decoded image data should not be nil")
            XCTAssertEqual(decodedFilename, "test_image.png")
            XCTAssertEqual(decodedAltText, "Test Alt Text")
        } else {
            XCTFail("Decoded asset type should be .uiImage")
        }
    }

    func test_phAsset_decoding_fails_with_expected_error() throws {
        // Given
        let fakeLocalIdentifier = "this_is_a_fake_local_identifier"
        let mockAsset = PHAssetMock(localIdentifier: fakeLocalIdentifier)
        let assetType = ProductImageAssetType.phAsset(asset: mockAsset)

        // Then
        XCTAssertThrowsError(try {
            let data = try JSONEncoder().encode(assetType)
            _ = try JSONDecoder().decode(ProductImageAssetType.self, from: data)
        }()) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertEqual(context.debugDescription, "No PHAsset found with localIdentifier \(fakeLocalIdentifier)")
            } else {
                XCTFail("Expected dataCorrupted error, got \(error)")
            }
        }
    }

    func test_decoding_unknown_asset_type_throws_error() throws {
        // Given
        let jsonData = """
        {
          "type": "unknownType"
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductImageAssetType.self, from: jsonData)) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertTrue(context.debugDescription.contains("Unknown type unknownType"))
            } else {
                XCTFail("Expected dataCorrupted error, but got: \(error)")
            }
        }
    }

    func test_invalid_base64Data_for_UIImage_throws_error() throws {
        // Given
        let jsonData = """
        {
          "type": "uiImage",
          "imageData": "INVALID_BASE64_DATA",
          "filename": "test.png",
          "altText": "Test Alt"
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductImageAssetType.self, from: jsonData)) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertTrue(context.debugDescription.contains("Invalid image data"))
            } else {
                XCTFail("Expected dataCorrupted error, got \(error)")
            }
        }
    }
}
