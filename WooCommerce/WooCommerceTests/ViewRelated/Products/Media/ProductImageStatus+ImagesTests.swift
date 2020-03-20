import Photos
import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductImageStatus_ImagesTests: XCTestCase {
    func testWithoutRemoteImages() {
        let statuses: [ProductImageStatus] = [
            .uploading(asset: PHAsset())
        ]
        XCTAssertEqual(statuses.images, [])
    }

    func testWithRemoteImages() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [
            .uploading(asset: PHAsset()),
            .remote(image: productImage)
        ]
        XCTAssertEqual(statuses.images, [productImage])
    }
}
