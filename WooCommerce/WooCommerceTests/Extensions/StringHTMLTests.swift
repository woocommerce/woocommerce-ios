import XCTest
@testable import WooCommerce


/// String+HTML Unit Tests
///
class StringHTMLTests: XCTestCase {

    /// Verifies that regular HTML Tags are effectively nuked
    ///
    func testRegularTagsAreCleanedUp() {
        let sampleHTML1 = "<a href='www.automattic.com'><b><i>LINK</i></b></a>"
        let sampleStripped1 = "LINK"

        XCTAssertEqual(sampleHTML1.strippedHTML, sampleStripped1)
    }

    /// Verifies that Hexa Entities are converted into plain Characters
    ///
    func testHexaCharactersAreConvertedIntoSimpleCharacters() {
        let sampleHTML2 = "&lt;&gt;&amp;&quot;&apos;"
        let sampleStripped2 = "<>&\"'"

        XCTAssertEqual(sampleHTML2.strippedHTML, sampleStripped2)
    }

    /// Verifies that Line Breaks are effectively converted into `\n` characters
    ///
    func testLineBreaksAreConvertedIntoNewlines() {
        let sampleHTML3 = "<br><br/>"
        let sampleStripped3 = "\n\n"

        XCTAssertEqual(sampleHTML3.strippedHTML, sampleStripped3)
    }

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
