import XCTest
@testable import WooCommerce

final class UIStackView_SubviewsTests: XCTestCase {

    // MARK: - `removeAllArrangedSubviews`

    func testRemovingAllArrangedSubviews() {
        let stackView = UIStackView(arrangedSubviews: [UIView(), UIView(), UILabel()])
        XCTAssertEqual(stackView.arrangedSubviews.count, 3)

        stackView.removeAllArrangedSubviews()
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }

    func testRemovingAllArrangedSubviewsFromAnEmptyStackView() {
        let stackView = UIStackView(arrangedSubviews: [])
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)

        stackView.removeAllArrangedSubviews()
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }

    // MARK: - `addArrangedSubviews`

    func testAddingArrangedSubviewsToAnEmptyStackView() {
        let stackView = UIStackView(arrangedSubviews: [])
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)

        let subviews = [UIView(), UIView(), UILabel()]
        stackView.addArrangedSubviews(subviews)
        XCTAssertEqual(stackView.arrangedSubviews.count, subviews.count)
        XCTAssertEqual(stackView.arrangedSubviews, subviews)
    }

    func testAddingArrangedSubviewsToANonEmptyStackView() {
        let stackView = UIStackView(arrangedSubviews: [UIView(), UIView(), UILabel()])
        XCTAssertEqual(stackView.arrangedSubviews.count, 3)

        let subviews = [UIView(), UIView(), UILabel()]
        stackView.addArrangedSubviews(subviews)
        XCTAssertEqual(stackView.arrangedSubviews.count, 6)

        let subviewsStartIndex = stackView.arrangedSubviews.count - subviews.count
        XCTAssertEqual(Array(stackView.arrangedSubviews[subviewsStartIndex...]), subviews)
    }

    func testAddingEmptyArrangedSubviews() {
        let stackView = UIStackView(arrangedSubviews: [UIView(), UIView(), UILabel()])
        XCTAssertEqual(stackView.arrangedSubviews.count, 3)

        stackView.addArrangedSubviews([])
        XCTAssertEqual(stackView.arrangedSubviews.count, 3)
    }
}
