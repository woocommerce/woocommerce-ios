import Photos
import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductImageStatus_HelpersTests: XCTestCase {
    // MARK: - `images`

    func testImagesReturnsEmptyIfThereAreNoRemoteImages() {
        let statuses: [ProductImageStatus] = [
            .uploading(asset: PHAsset())
        ]
        XCTAssertEqual(statuses.images, [])
    }

    func testImagesReturnsProductImagesIfThereAreRemoteImages() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [
            .uploading(asset: PHAsset()),
            .remote(image: productImage)
        ]
        XCTAssertEqual(statuses.images, [productImage])
    }

    // MARK: - `hasPendingUpload`

    func testHasPendingUploadWithNoImages() {
        let statuses: [ProductImageStatus] = []
        XCTAssertFalse(statuses.hasPendingUpload)
    }

    func testHasPendingUploadWithAllRemoteImages() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [.remote(image: productImage), .remote(image: productImage)]
        XCTAssertFalse(statuses.hasPendingUpload)
    }

    func testHasPendingUploadWithBothStatusTypes() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [
            .uploading(asset: PHAsset()),
            .remote(image: productImage)
        ]
        XCTAssertTrue(statuses.hasPendingUpload)
    }
}
