import XCTest
@testable import WooCommerce

final class BarcodeScannerFrameScalerTests: XCTestCase {
    /// Imagine the rect is iPhone in portrait, and the target frame is wider than the phone width when its height is scaled to fill the vertical dimension.
    func test_scaling_to_a_target_size_that_has_higher_aspect_ratio() {
        let rect = CGRect(x: 0, y: 201.66, width: 414, height: 268.8)
        let referenceRect = CGRect(x: 0, y: 0, width: 414, height: 672)
        let targetRect = CGRect(x: 0, y: 0, width: 1080, height: 1440)
        let scaledRect = BarcodeScannerFrameScaler.scaling(rect, in: referenceRect, to: targetRect)
        XCTAssertEqual(scaledRect, CGRect(x: 96.42857142857143, y: 432.12857142857143, width: 887.1428571428571, height: 576.0))
    }

    /// Imagine the rect is iPhone in landscape, and the target frame is taller than the phone height when its width is scaled to fill the horizontal dimension.
    func test_scaling_to_a_size_that_that_has_lower_aspect_ratio() {
        let rect = CGRect(x: 0, y: 85, width: 736, height: 200)
        let referenceRect = CGRect(x: 0, y: 0, width: 736, height: 370)
        let targetRect = CGRect(x: 0, y: 0, width: 1440, height: 1080)
        let scaledRect = BarcodeScannerFrameScaler.scaling(rect, in: referenceRect, to: targetRect)
        XCTAssertEqual(scaledRect, CGRect(x: 0, y: 344.3478260869565, width: 1440, height: 391.30434782608694))
    }
}
