import XCTest
@testable import WooCommerce

final class UIView_SubviewsAxisTests: XCTestCase {
    func testTwoSubviewsAxisWithNoSubviews() {
        let view = UIView(frame: .zero)
        XCTAssertNil(view.axisOfTwoSubviews())
    }

    func testTwoSubviewsAxisWithVerticalSubviews() {
        let view = UIView(frame: .zero)
        let subview1 = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        let subview2 = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 10), size: CGSize(width: 10, height: 10)))
        [subview2, subview1].forEach(view.addSubview(_:))

        XCTAssertEqual(view.axisOfTwoSubviews(), .vertical)
    }

    func testTwoSubviewsAxisWithVerticallyOverlappingSubviews() {
        let view = UIView(frame: .zero)
        let subview1 = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        let subview2 = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 5), size: CGSize(width: 10, height: 10)))
        [subview2, subview1].forEach(view.addSubview(_:))

        XCTAssertEqual(view.axisOfTwoSubviews(), .horizontal)
    }

}
