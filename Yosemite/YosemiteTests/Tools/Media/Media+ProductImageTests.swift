import XCTest
@testable import Yosemite

final class Media_ProductImageTests: XCTestCase {
    func testMediaToProductImage() {
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let date = Date(timeIntervalSince1970: 1565892875)
        let mediaID: Int64 = 134
        let source = "pic.com"
        let name = "woo!"
        let alt = "woo too"
        let media = Media(mediaID: mediaID, date: date,
                          fileExtension: "jpg", mimeType: "image/jpeg",
                          src: source, thumbnailURL: "https://test.com/pic1",
                          name: name, alt: alt,
                          height: 136, width: nil)
        let expectedProductImage = ProductImage(imageID: mediaID,
                                                dateCreated: date,
                                                dateModified: date,
                                                src: source,
                                                name: name,
                                                alt: alt)
        XCTAssertEqual(media.toProductImage, expectedProductImage)
    }
}
