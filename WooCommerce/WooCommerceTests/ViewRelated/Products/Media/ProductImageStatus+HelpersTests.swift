import Photos
import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductImageStatus_HelpersTests: XCTestCase {
    // MARK: - `images`

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

    // MARK: - `hasImagesPendingUpload`

    func testHasImagesPendingUploadWithNoImages() {
        let statuses: [ProductImageStatus] = []
        XCTAssertFalse(statuses.hasImagesPendingUpload)
    }

    func testHasImagesPendingUploadWithAllRemoteImages() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [.remote(image: productImage), .remote(image: productImage)]
        XCTAssertFalse(statuses.hasImagesPendingUpload)
    }

    func testHasImagesPendingUploadWithBothStatusTypes() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [
            .uploading(asset: PHAsset()),
            .remote(image: productImage)
        ]
        XCTAssertTrue(statuses.hasImagesPendingUpload)
    }
}
