import XCTest
import UIKit
@testable import WooCommerce

final class NSAttributedString_AttributesTests: XCTestCase {
    func test_adding_attributes_applies_to_the_whole_range() {
        // Given
        let originalString = NSAttributedString(string: "It’s seamless to <a href=\"https://docs.woocommerce.com\">enable Apple Pay with Stripe</a>")

        // When
        let string = originalString.addingAttributes([.foregroundColor: UIColor.purple])

        // Then
        var effectiveRange = NSRange()
        XCTAssertEqual(string.attributes(at: 0, effectiveRange: &effectiveRange) as? [NSAttributedString.Key: UIColor], [
            .foregroundColor: UIColor.purple
        ])
        XCTAssertEqual(effectiveRange, .init(location: 0, length: originalString.length))
    }
}
