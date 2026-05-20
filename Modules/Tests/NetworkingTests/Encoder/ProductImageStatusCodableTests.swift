import XCTest
import Photos
@testable import Networking
@testable import NetworkingCore

final class ProductImageStatusCodableTests: XCTestCase {

    func test_uploading_encodes_and_decodes_correctly() throws {
        // Given
        let status = ProductImageStatus.uploading(
            asset: .uiImage(image: UIImage.checkmark, filename: "test.png", altText: "Test Alt"),
            siteID: 12345,
            productID: .product(id: 999)
        )

        // When
        let encodedData = try JSONEncoder().encode(status)
        let decodedStatus = try JSONDecoder().decode(ProductImageStatus.self, from: encodedData)

        // Then
        guard case let .uploading(.uiImage(decodedImage, decodedFilename, decodedAltText), siteID, productID) = decodedStatus else {
            XCTFail("Decoded status should be .uploading with .uiImage asset")
            return
        }

        XCTAssertNotNil(decodedImage.pngData(), "Decoded image data should not be nil")
        XCTAssertEqual(decodedFilename, "test.png")
        XCTAssertEqual(decodedAltText, "Test Alt")
        XCTAssertEqual(siteID, 12345)
        XCTAssertEqual(productID, .product(id: 999))
    }

    func test_uploading_phAsset_decoding_fails_with_expected_error() throws {
        // Given
        let fakeLocalIdentifier = "4321"
        let mockAsset = PHAssetMock(localIdentifier: fakeLocalIdentifier)
        let status = ProductImageStatus.uploading(
            asset: .phAsset(asset: mockAsset),
            siteID: 11111,
            productID: .variation(productID: 43, variationID: 55)
        )

        // When
        let encodedData = try JSONEncoder().encode(status)

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductImageStatus.self, from: encodedData)) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertEqual(context.debugDescription, "No PHAsset found with localIdentifier \(fakeLocalIdentifier)")
            } else {
                XCTFail("Expected dataCorrupted error, but got: \(error)")
            }
        }
    }

    func test_remote_encodes_and_decodes_correctly() throws {
        // Given
        let testImage = ProductImage(
            imageID: 111,
            dateCreated: Date(),
            dateModified: nil,
            src: "https://example.com/image.png",
            name: "Example Image",
            alt: "Example Alt"
        )
        let status = ProductImageStatus.remote(
            image: testImage,
            siteID: 98765,
            productID: .variation(productID: 1, variationID: 2)
        )

        // When
        let encodedData = try JSONEncoder().encode(status)
        let decodedStatus = try JSONDecoder().decode(ProductImageStatus.self, from: encodedData)

        // Then
        guard case let .remote(image, siteID, productID) = decodedStatus else {
            XCTFail("Decoded status should be .remote")
            return
        }

        XCTAssertEqual(image.imageID, 111)
        XCTAssertEqual(image.src, "https://example.com/image.png")
        XCTAssertEqual(image.name, "Example Image")
        XCTAssertEqual(image.alt, "Example Alt")
        XCTAssertEqual(siteID, 98765)
        XCTAssertEqual(productID, .variation(productID: 1, variationID: 2))
    }

    func test_uploadFailure_encodes_and_decodes_correctly() throws {
        // Given
        let error = NSError(domain: "TestErrorDomain", code: 404, userInfo: ["info": "not found"])
        let status = ProductImageStatus.uploadFailure(
            asset: .uiImage(image: UIImage.checkmark, filename: "failure.png", altText: nil),
            error: error,
            siteID: 55555,
            productID: .product(id: 123)
        )

        // When
        let encodedData = try JSONEncoder().encode(status)
        let decodedStatus = try JSONDecoder().decode(ProductImageStatus.self, from: encodedData)

        // Then
        guard case let .uploadFailure(.uiImage(_, decodedFilename, decodedAltText), decodedError as NSError, siteID, productID) = decodedStatus else {
            XCTFail("Decoded status should be .uploadFailure with .uiImage asset")
            return
        }

        XCTAssertEqual(decodedFilename, "failure.png")
        XCTAssertNil(decodedAltText)
        XCTAssertEqual(decodedError.domain, "TestErrorDomain")
        XCTAssertEqual(decodedError.code, 404)
        XCTAssertEqual(decodedError.userInfo["info"] as? String, "not found")
        XCTAssertEqual(siteID, 55555)
        XCTAssertEqual(productID, .product(id: 123))
    }

    func test_decoding_unknown_status_type_throws_error() throws {
        // Given
        let jsonString = """
            {
              "type": "unknownType",
              "siteID": 1234,
              "productID": {
                "type": "product",
                "id": 999
              }
            }
            """
        let data = jsonString.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductImageStatus.self, from: data)) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertTrue(context.debugDescription.contains("Invalid type value"))
            } else {
                XCTFail("Expected dataCorrupted error, but got: \(error)")
            }
        }
    }

    func test_invalid_Base64Data_for_UIImage_throws_error() throws {
        // Given:
        let jsonString = """
            {
              "type": "uploading",
              "asset": {
                "type": "uiImage",
                "imageData": "INVALID_BASE64_DATA",
                "filename": "base64",
                "altText": "BASE64"
              },
              "siteID": 111,
              "productID": {
                "type": "product",
                "id": 1
              }
            }
            """
        let data = jsonString.data(using: .utf8)!

        // When / Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductImageStatus.self, from: data)) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertTrue(context.debugDescription.contains("Invalid image data"))
            } else {
                XCTFail("Expected dataCorrupted error, got \(error)")
            }
        }
    }
}
