import XCTest
@testable import WooCommerce

class ApplicationLogViewModelTests: XCTestCase {
    func testExcludedTypes() {
        let model = ApplicationLogViewModel(logText: "")
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
}
