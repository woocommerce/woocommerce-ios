import XCTest
@testable import WooCommerce


/// String+HTML Unit Tests
///
class StringHTMLTests: XCTestCase {

    func testHTMLTagsRemovedWithHTMLText() {
        let sampleHTML = "<a href='www.automattic.com'><b><i>LINK</i></b></a>"
        let expectedString = "LINK"

        XCTAssertEqual(sampleHTML.removedHTMLTags, expectedString)
    }

    func testHTMLTagsRemovedWithLineBreaks() {
        let sampleHTML = "<br><br/>"
        let expectedString = ""

        XCTAssertEqual(sampleHTML.removedHTMLTags, expectedString)
    }
}
