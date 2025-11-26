import XCTest
import ViewInspector
import SwiftUI
import Combine
@testable import WooCommerce

final class BookingDateTimeFilterViewTests: XCTestCase {
    func test_clear_button_is_disabled_initially_when_no_dates_selected() throws {
        let sut = BookingDateTimeFilterView(startDate: nil, endDate: nil, onSelection: { _, _ in })
        let view = try sut.inspect()

        let button = try view.find(button: "Clear")
        XCTAssertTrue(button.isDisabled())
    }

    func test_clear_button_is_enabled_when_dates_selected() throws {
        let date = Date()
        let sut = BookingDateTimeFilterView(startDate: date, endDate: date, onSelection: { _, _ in })
        let view = try sut.inspect()

        let button = try view.find(button: "Clear")
        XCTAssertFalse(button.isDisabled())
    }
}
