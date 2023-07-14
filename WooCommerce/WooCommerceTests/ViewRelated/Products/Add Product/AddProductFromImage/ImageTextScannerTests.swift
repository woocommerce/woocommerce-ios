import TestKit
import XCTest

@testable import WooCommerce

final class ImageTextScannerTests: XCTestCase {
    private let scanner = ImageTextScanner()

    func test_scanText_returns_empty_list_from_image_without_text() async throws {
        // Given
        let imageWithoutText = UIImage.addImage

        // When
        let scannedTexts = try await scanner.scanText(from: imageWithoutText)

        // Then
        XCTAssertEqual(scannedTexts, [])
    }

    func test_scanText_returns_text_from_image_with_text() async throws {
        // Given
        let imageWithText = UIImage.wooLogoPrologueImage

        // When
        let scannedTexts = try await scanner.scanText(from: imageWithText)

        // Then
        XCTAssertTrue(scannedTexts.isNotEmpty)
    }
}
