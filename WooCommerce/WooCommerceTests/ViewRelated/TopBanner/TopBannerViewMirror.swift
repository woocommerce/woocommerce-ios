import UIKit
import XCTest

@testable import WooCommerce

/// Represents the private properties of `TopBannerView`.
struct TopBannerViewMirror {
    let actionStackView: UIStackView
    let actionButtons: [UIButton]

    init(from view: TopBannerView) throws {
        let mirror = Mirror(reflecting: view)

        self.actionStackView = try XCTUnwrap(mirror.descendant("actionStackView") as? UIStackView)
        self.actionButtons = try XCTUnwrap(mirror.descendant("actionButtons") as? [UIButton])
    }
}
