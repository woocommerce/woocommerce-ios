import XCTest
@testable import Networking

final class String_HTMLTests: XCTestCase {

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

}
