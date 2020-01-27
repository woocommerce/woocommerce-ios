import MobileCoreServices
import XCTest
@testable import Yosemite

final class URL_MediaTests: XCTestCase {

    // MARK: tests for `mimeTypeForPathExtension`

    func testMimeTypeForJPEGFileURL() {
        let url = URL(string: "/test/product.jpeg")
        let expectedMimeType = "image/jpeg"
        XCTAssertEqual(url?.mimeTypeForPathExtension, expectedMimeType)
    }

    func testMimeTypeForJPGFileURL() {
        let url = URL(string: "/test/product.jpg")
        let expectedMimeType = "image/jpeg"
        XCTAssertEqual(url?.mimeTypeForPathExtension, expectedMimeType)
    }

    func testMimeTypeForGIFFileURL() {
        let url = URL(string: "/test/product.gif")
        let expectedMimeType = "image/gif"
        XCTAssertEqual(url?.mimeTypeForPathExtension, expectedMimeType)
    }

    func testMimeTypeForPNGFileURL() {
        let url = URL(string: "/test/product.png")
        let expectedMimeType = "image/png"
        XCTAssertEqual(url?.mimeTypeForPathExtension, expectedMimeType)
    }

    // MARK: tests for `fileExtensionForUTType`

    func testFileExtensionForJPEGType() {
        let expectedFileExtension = "jpeg"
        XCTAssertEqual(URL.fileExtensionForUTType(kUTTypeJPEG as String), expectedFileExtension)
    }

    func testFileExtensionForGIFType() {
        let expectedFileExtension = "gif"
        XCTAssertEqual(URL.fileExtensionForUTType(kUTTypeGIF as String), expectedFileExtension)
    }

    func testFileExtensionForPNGType() {
        let expectedFileExtension = "png"
        XCTAssertEqual(URL.fileExtensionForUTType(kUTTypePNG as String), expectedFileExtension)
    }
}
