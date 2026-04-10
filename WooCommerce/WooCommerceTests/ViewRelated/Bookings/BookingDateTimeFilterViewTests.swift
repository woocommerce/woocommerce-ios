import XCTest
import ViewInspector
import SwiftUI
import Combine
@testable import WooCommerce

final class BookingDateTimeFilterViewTests: XCTestCase {
    func test_clear_button_is_not_rendered_initially_when_no_dates_selected() throws {
        let sut = BookingDateTimeFilterView(startDate: nil, endDate: nil, onSelection: { _, _ in })
        let view = try sut.inspect()

        XCTAssertThrowsError(try view.find(button: "Clear"))
    }

    func test_clear_button_is_rendered_when_dates_selected() throws {
        let date = Date()
        let sut = BookingDateTimeFilterView(startDate: date, endDate: date, onSelection: { _, _ in })
        let view = try sut.inspect()

        _ = try view.find(button: "Clear")
    }
}
