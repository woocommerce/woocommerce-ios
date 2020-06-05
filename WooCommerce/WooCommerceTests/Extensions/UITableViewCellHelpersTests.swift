import XCTest
@testable import WooCommerce


// UITableViewCell+Helpers: Unit Tests
//
final class UITableViewCellHelpersTests: XCTestCase {

    /// Verifies that `reuseIdentifier` class method effectively returns a string that doesn't contain the class's module.
    ///
    func testReuseIdentifierEffectivelyReturnsClassnameWithNoNamespaces() {
        XCTAssertEqual(EmptyStoresTableViewCell.reuseIdentifier, "EmptyStoresTableViewCell")
    }

    func testFindSectionTopSeparatorReturnsTheSeparatorView() {
        // Given
        let cell = UITableViewCell()

        // Dummy subviews
        cell.addSubview(UIView(frame: .init(x: 0, y: 0, width: 263, height: 300)))
        cell.addSubview(UIView(frame: .init(x: 100, y: 20, width: 120, height: 76)))

        // We'll only be simulating the separator view because it looks like it's the
        // `UITableView` itself that creates and adds the separator view as a child.
        let actualSeparatorView =
            UIView(frame: .init(origin: .zero, size: .init(width: cell.bounds.width, height: 0.5)))
        cell.addSubview(actualSeparatorView)

        // When
        let foundSeparatorView = cell.findSectionTopSeparator()

        // Then
        XCTAssertNotNil(foundSeparatorView)
        assertThat(actualSeparatorView, isIdenticalTo: foundSeparatorView)
    }

    /// Tests the scenario where a device us using the largest font size. In this case,
    /// the separator height is _expected_ to be 1.
    ///
    func testFindSectionTopSeparatorReturnsTheSeparatorViewWithHeightEqualToOne() {
        // Given
        let cell = UITableViewCell()

        // Dummy subviews
        cell.addSubview(UIView(frame: .init(x: 0, y: 0, width: 263, height: 300)))
        cell.addSubview(UIView(frame: .init(x: 100, y: 20, width: 120, height: 76)))

        // We'll only be simulating the separator view because it looks like it's the
        // `UITableView` itself that creates and adds the separator view as a child.
        let actualSeparatorView =
            UIView(frame: .init(origin: .zero, size: .init(width: cell.bounds.width, height: 1)))
        cell.addSubview(actualSeparatorView)

        // When
        let foundSeparatorView = cell.findSectionTopSeparator()

        // Then
        XCTAssertNotNil(foundSeparatorView)
        assertThat(actualSeparatorView, isIdenticalTo: foundSeparatorView)
    }

    func testFindSectionTopSeparatorReturnsNilIfThereIsNoMatchingSeparatorView() {
        // Given
        let cell = UITableViewCell()

        // Dummy subviews
        cell.addSubview(UIView(frame: .init(x: 0, y: 0, width: 263, height: 300)))
        cell.addSubview(UIView(frame: .init(x: 100, y: 20, width: 120, height: 76)))

        // When
        let foundSeparatorView = cell.findSectionTopSeparator()

        // Then
        XCTAssertNil(foundSeparatorView)
    }
}
