import XCTest
@testable import WooCommerce

class ApplicationLogViewModelTests: XCTestCase {
    func test_title() {
        let model = ApplicationLogViewModel(logText: "", logDate: "Today")
        XCTAssertEqual(model.title, "Today")
    }

    func test_excluded_types() {
        let model = ApplicationLogViewModel(logText: "", logDate: "")
        let excludedTypes = model.excludedActivityTypes
        let expectedTypes: Set<UIActivity.ActivityType> = [
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .message,
            .print,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .openInIBooks,
            .markupAsPDF
        ]
        XCTAssertEqual(excludedTypes, expectedTypes)
    }

    func test_log_line_parses_correct_date() {
        let logText = "2021/06/07 11:59:46:454  🔵 Tracked application_opened"
        let logDate = "Today"
        let model = ApplicationLogViewModel(logText: logText, logDate: logDate)
        XCTAssertEqual(model.lines.count, 1)
        let line = model.lines[0]
        XCTAssertNotNil(line.date)
        XCTAssertEqual(line.dateText, "Jun 7, 2021 at 11:59:46 AM")
        XCTAssertEqual(line.text, "🔵 Tracked application_opened")
    }

    func test_log_line_does_not_parse_incorrect_date() {
        let logText = "2021/06/07  🔵 Tracked application_opened"
        let logDate = "Today"
        let model = ApplicationLogViewModel(logText: logText, logDate: logDate)
        XCTAssertEqual(model.lines.count, 1)
        let line = model.lines[0]
        XCTAssertNil(line.date)
        XCTAssertNil(line.dateText)
        XCTAssertEqual(line.text, "2021/06/07  🔵 Tracked application_opened")
    }

    func test_log_line_parses_no_date() {
        let logText = "🔵 Tracked application_opened"
        let logDate = "Today"
        let model = ApplicationLogViewModel(logText: logText, logDate: logDate)
        XCTAssertEqual(model.lines.count, 1)
        let line = model.lines[0]
        XCTAssertNil(line.date)
        XCTAssertNil(line.dateText)
        XCTAssertEqual(line.text, "🔵 Tracked application_opened")
    }

    func test_filteredLines_matches_substring_case_insensitively() {
        // Given
        let logText = """
        2021/06/07 11:59:42:636  📱 Registering for Remote Notifications...
        2021/06/07 11:59:46:454  🔵 Tracked application_opened
        """
        let model = ApplicationLogViewModel(logText: logText, logDate: "Today")

        // When
        // A partial, differently-cased query must match, since the point is finding events without exact casing.
        model.searchText = "TRACKED"

        // Then
        // Filtering is driven by the debounced search text, so wait for it to propagate.
        waitUntil {
            model.filteredLines.count == 1
        }
        XCTAssertEqual(model.filteredLines.first?.text, "🔵 Tracked application_opened")
    }
}
