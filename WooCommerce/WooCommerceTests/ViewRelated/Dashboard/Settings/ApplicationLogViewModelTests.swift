import XCTest
@testable import WooCommerce

class ApplicationLogViewModelTests: XCTestCase {
    func testExcludedTypes() {
        let model = ApplicationLogViewModel(logText: "")
        let excludedTypes = Set(model.assembleExcludedSupportTypes())
        let expectedTypes: Set<UIActivity.ActivityType> = Set([
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
        ])
        XCTAssertEqual(excludedTypes, expectedTypes)
    }
}
