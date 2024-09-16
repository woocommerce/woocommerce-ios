import XCTest

@testable import WooCommerce

final class PointOfSaleAssetsTests: XCTestCase {
    func test_all_asset_imageNames_can_be_used_to_create_images() {
        /// Note that we use `UIImage` not `Image` here, even though we should only use
        /// `Image(_ name:)` in production POS code. `Image` doesn't let us test whether the asset
        /// exists or not, where `UIImage` will return nil if we can't find the asset in the bundle.
        for asset in PointOfSaleAssets.allCases {
            XCTAssertNotNil(
                UIImage(named: asset.imageName),
                "Could not create an image for \(asset.imageName) – check the " +
                "name, and that the image is in the bundle.")
        }
    }
}
