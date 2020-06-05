
import Foundation
import XCTest

import Yosemite

@testable import WooCommerce

/// Tests for `ProductDetailsTableViewCell`
///
final class ProductDetailsTableViewCellTests: XCTestCase {

    func testItDoesNotDisplayTheSectionTopSeparatorView() {
        // Given
        let cell: ProductDetailsTableViewCell = .instantiateFromNib()

        // Simulate that the `UITableView` added a separator
        let separatorView =
            UIView(frame: .init(origin: .zero, size: .init(width: cell.bounds.width, height: 0.5)))
        cell.addSubview(separatorView)

        XCTAssertFalse(separatorView.isHidden)

        // When
        cell.layoutSubviews()

        // Then
        XCTAssertTrue(separatorView.isHidden)
    }
}
