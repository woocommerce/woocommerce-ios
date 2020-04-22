import XCTest
@testable import WooCommerce


/// Array+IndexPath: Unit Tests
///
import XCTest

final class ArrayIndexPathTests: XCTestCase {

    private var sections: [Section] = [Section(rows: [.simplenote, .wordpress]), Section(rows: [.woocommerce]), Section(rows: [.wordpress])]

    func testIndexPathForRowReturnTheRightIndexPath() {

        /// Row in section 1
        ///
        let expectedIndexPath = IndexPath(row: 0, section: 1)
        let result = sections.indexPathForRow(.woocommerce)
        XCTAssertEqual(expectedIndexPath, result)
    }

    func testIndexPathForRowReturnTheFirstRowFound() {
        /// .wordpress is a row present in two different section. The indexPath returned should be the first found
        ///
        let expectedIndexPath = IndexPath(row: 1, section: 0)
        let result = sections.indexPathForRow(.wordpress)

        XCTAssertEqual(expectedIndexPath, result)
    }

    func testIndexPathForRowReturnNull() {
        /// This row doesn't exist in the initial sections array. The method should return nil
        ///
        let result = sections.indexPathForRow(.tumblr)
        XCTAssertNil(result)
    }
}

// MARK: - Row and Sections which conform to RowIterable
//
private extension ArrayIndexPathTests {

    /// Table Rows
    ///
    enum Row {
        case woocommerce
        case wordpress
        case simplenote
        case tumblr


        var reuseIdentifier: String {
            return "The same identifier for every row"
        }
    }

    /// Table Sections
    ///
    struct Section: RowIterable {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }
    }
}
