import Photos
import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductImageStatus_HelpersTests: XCTestCase {

    private let siteID: Int64 = 1234
    private let productID = ProductOrVariationID.product(id: 5678)

    // MARK: - `images`

    func testImagesReturnsEmptyIfThereAreNoRemoteImages() {
        let statuses: [ProductImageStatus] = [
            .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID)
        ]
        XCTAssertEqual(statuses.images, [])
    }

    func testImagesReturnsProductImagesIfThereAreRemoteImages() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [
            .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID),
            .remote(image: productImage, siteID: siteID, productID: productID)
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

        let statuses: [ProductImageStatus] = [.remote(image: productImage, siteID: siteID, productID: productID),
                                              .remote(image: productImage, siteID: siteID, productID: productID)]
        XCTAssertFalse(statuses.hasPendingUpload)
    }

    func testHasPendingUploadWithBothStatusTypes() {
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)

        let statuses: [ProductImageStatus] = [
            .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID),
            .remote(image: productImage, siteID: siteID, productID: productID)
        ]
        XCTAssertTrue(statuses.hasPendingUpload)
    }

    // MARK: - `dragItemIdentifier`

    func test_dragItemIdentifier_is_correct_for_remote_image() {
        // Given
        let productImage = ProductImage(imageID: 17, dateCreated: Date(), dateModified: Date(), src: "", name: nil, alt: nil)
        let status = ProductImageStatus.remote(image: productImage, siteID: siteID, productID: productID)
        let expectedIdentifier = "\(17)"

        // When
        let obtainedIdentifier = status.dragItemIdentifier

        // Then
        XCTAssertEqual(obtainedIdentifier, expectedIdentifier)
    }

    func test_dragItemIdentifier_is_correct_for_uploading_asset() {
        // Given
        let asset = PHAsset()
        let status = ProductImageStatus.uploading(asset: .phAsset(asset: asset), siteID: siteID, productID: productID)
        let expectedIdentifier = asset.identifier()

        // When
        let obtainedIdentifier = status.dragItemIdentifier

        // Then
        XCTAssertEqual(obtainedIdentifier, expectedIdentifier)
    }
}
