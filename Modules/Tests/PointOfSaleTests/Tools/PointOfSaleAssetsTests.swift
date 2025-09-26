import XCTest

@testable import PointOfSale

final class PointOfSaleAssetsTests: XCTestCase {
    func test_all_asset_imageNames_can_be_used_to_create_images() {
        /// Note that we use `UIImage` not `Image` here, even though we should only use
        /// `Image(_ name:)` in production POS code. `Image` doesn't let us test whether the asset
        /// exists or not, where `UIImage` will return nil if we can't find the asset in the bundle.
        for asset in PointOfSaleAssets.allCases {
            XCTAssertNotNil(
                UIImage(named: asset.imageName, in: .pointOfSale, compatibleWith: nil),
                "Could not create an image for \(asset.imageName) – check the " +
                "name, and that the image is in the bundle.")
        }
    }
}

extension Bundle {
    static var pointOfSale: Bundle {
#if DEBUG
        // Workaround for https://forums.swift.org/t/swift-5-3-swiftpm-resources-in-tests-uses-wrong-bundle-path/37051
        if let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"],
           let bundle = Bundle(path: "\(testBundlePath)/Modules_PointOfSale.bundle") {
            return bundle
        }
#endif
        return .module
    }
}
