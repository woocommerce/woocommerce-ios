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

    /// Confidence-check that stripping works in the background thread too.
    ///
    func testItCanStripHTMLInABackgroundThread() {
        let source = "<p><strong>Pellentesque <em>habitant</em> morbi tristique</strong></p>"

        var stripped: String?
        waitForExpectation { expectation in
            DispatchQueue.global().async {
                stripped = source.strippedHTML
                expectation.fulfill()
            }
        }

        XCTAssertEqual(stripped, "Pellentesque habitant morbi tristique")
    }

    /// Test with lotsa HTML tags
    ///
    func testItCanStripHTMLFromALargeSource() {
        // Given
        let source =
            """
            <h1>HTML Ipsum Presents</h1>

            <p><strong>Pellentesque habitant morbi tristique</strong> senectus et netus et malesuada fames ac turpis 
                    egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. Donec eu 
                    libero sit amet quam egestas semper. <em>Aenean ultricies mi vitae est.</em> Mauris placerat 
                    eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra. Vestibulum erat wisi, 
                    condimentum sed, <code>commodo vitae</code>, ornare sit amet, wisi. Aenean fermentum, elit eget 
                    tincidunt condimentum, eros ipsum rutrum orci, sagittis tempus lacus enim ac dui. 
                    <a href="#">Donec non enim</a> in turpis pulvinar facilisis. Ut felis.</p>

            <h2>Header Level 2</h2>

            <ol>
               <li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.</li>
               <li>Aliquam tincidunt mauris eu risus.</li>
            </ol>

            <blockquote><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus magna. Cras in mi at felis
                    aliquet congue. Ut a est eget ligula molestie gravida. Curabitur massa. Donec eleifend, libero at 
                    sagittis mollis, tellus est malesuada tellus, at luctus turpis elit sit amet quam. Vivamus 
                    pretium ornare est.</p></blockquote>

            <h3>Header Level 3</h3>

            <ul>
               <li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.</li>
               <li>Aliquam tincidunt mauris eu risus.</li>
            </ul>

            <pre><code>
            #header h1 a {
              display: block;
              width: 300px;
              height: 80px;
            }
            </code></pre>
            """

        // When
        let stripped = source.strippedHTML

        // Then
        let expected =
            """
            HTML Ipsum Presents

            Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis 
                    egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. Donec eu 
                    libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat 
                    eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra. Vestibulum erat wisi, 
                    condimentum sed, commodo vitae, ornare sit amet, wisi. Aenean fermentum, elit eget 
                    tincidunt condimentum, eros ipsum rutrum orci, sagittis tempus lacus enim ac dui. 
                    Donec non enim in turpis pulvinar facilisis. Ut felis.

            Header Level 2

            Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
               Aliquam tincidunt mauris eu risus.
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus magna. Cras in mi at felis
                    aliquet congue. Ut a est eget ligula molestie gravida. Curabitur massa. Donec eleifend, libero at 
                    sagittis mollis, tellus est malesuada tellus, at luctus turpis elit sit amet quam. Vivamus 
                    pretium ornare est.

            Header Level 3

            Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
               Aliquam tincidunt mauris eu risus.

            #header h1 a {
              display: block;
              width: 300px;
              height: 80px;
            }

            """

        XCTAssertEqual(stripped, expected)
    }

}
