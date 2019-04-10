import XCTest
@testable import WooCommerce
@testable import Networking


/// StringFormatter Unit Tests
///
class StringFormatterTests: XCTestCase {

    /// Sample Style
    ///
    private let watermarkStyle: StringStyles.Style = [.foregroundColor: UIColor.red]

    /// Sample Quoted Text
    ///
    private let sampleQuotedText = "Something here \"and this should have a watermark style\" test wordpress.com"

    /// Sample Long Text
    ///
    private let sampleLongText = """
                                 Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry’s \
                                 standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make \
                                 a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, \
                                 remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing \
                                 Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions \
                                 of Lorem Ipsum.
                                 """

    /// Sample URL
    ///
    private let sampleURL = NSURL(string: "wordpress.com")!

    /// Sample Color
    ///
    private let sampleColor = UIColor.red

    /// Link Descriptor
    ///
    private let sampleLinkDescriptor: StringDescriptor = {
        let range = NSRange(location: 61, length: 13)
        let url = URL(string: "wordpress.com")!
        return NoteRange(type: nil, range: range, url: url, identifier: nil, postID: nil, siteID: nil, value: nil)
    }()

    /// Value Descriptor
    ///
    private let sampleValueDescriptor: StringDescriptor = {
        let range = NSRange(location: 0, length: 10)
        let value = "REPLACEMENT!"
        return NoteRange(type: nil, range: range, url: nil, identifier: nil, postID: nil, siteID: nil, value: value)
    }()



    /// Verifies that Quoted Text gets the Italics attributes.
    ///
    func testQuotedTextGetsItalicsStyleApplied() {
        let styles = StringStyles(regular: [:], italics: watermarkStyle)
        let text = StringFormatter().format(text: sampleQuotedText, with: styles, using: [])
        let quotedRange = Scanner(string: sampleQuotedText).scanQuotedRanges().first!

        XCTAssertTrue(text.isAttributeContainedExclusively(in: quotedRange, key: .foregroundColor, value: sampleColor))
    }

    /// Verifies that Long Text with truncating tail footnote style will get the Truncating Tail paragraph style
    ///
    func testLongTextGetsTailTruncatedStyleApplied() {
        let styles = StringStyles.snippet
        let text = StringFormatter().format(text: sampleLongText, with: styles, using: [])

        let textAttributes = text.attributes(at: 0, effectiveRange: nil)

        let textAttributesContainsParagraphStyle = textAttributes.keys.contains(.paragraphStyle)
        if textAttributesContainsParagraphStyle {
            let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle
            XCTAssertEqual(paragraphStyle, NSParagraphStyle.truncatingTailFootnote)
        } else {
            XCTFail()
        }
    }

    /// Verifies that the Descriptor's Value gets injected in the target range.
    ///
    func testDescriptorValueGetsInjectedInTheTargetRange() {
        let styles = StringStyles(regular: [:], link: watermarkStyle)
        let text = StringFormatter().format(text: sampleQuotedText, with: styles, using: [sampleValueDescriptor])
        let expected = "REPLACEMENT! here \"and this should have a watermark style\" test wordpress.com"

        XCTAssertEqual(expected, text.string)
    }

    /// Verifies that the Link Style is applied over any Descriptor with URL.
    ///
    func testDescriptorsContainingUrlGetTheLinkStyleAppliedOverTheTargetRange() {
        let styles = StringStyles(regular: [:], link: watermarkStyle)
        let text = StringFormatter().format(text: sampleQuotedText, with: styles, using: [sampleLinkDescriptor])
        let range = sampleLinkDescriptor.range

        XCTAssertTrue(text.isAttributeContainedExclusively(in: range, key: .foregroundColor, value: sampleColor))
        XCTAssertTrue(text.isAttributeContainedExclusively(in: range, key: .link, value: sampleURL))
    }

    /// Verifies that the Regular Attributes are applied to the entire string.
    ///
    func testRegularAttributesAreAppliedToTheEntireString() {
        let styles = StringStyles(regular: watermarkStyle)
        let text = StringFormatter().format(text: sampleQuotedText, with: styles, using: [])
        let fullRange = NSRange(location: 0, length: text.length)

        XCTAssertTrue(text.isAttributeContainedExclusively(in: fullRange, key: .foregroundColor, value: sampleColor))
    }

    /// Verifies that a Tab + Space maps into two HairSpace Unicode Chars.
    ///
    func testTabSuceededBySpaceGetsReplacedByTwoHairSpaces() {
        let sample = "\t something"
        let expected = String.hairSpace + String.hairSpace + "something"
        let text = StringFormatter().format(text: sample, with: .body, using: [])

        XCTAssertEqual(text.string, expected)
    }

    /// Verifies that Tabs are mapped into HairSpace Chars.
    ///
    func testTabsAreMappedIntoHairSpaces() {
        let sample = " \t\t@\t.\t,"
        let expected = String.space + String.hairSpace + String.hairSpace + "@" + String.hairSpace + "." + String.hairSpace + ","
        let text = StringFormatter().format(text: sample, with: .body, using: [])

        XCTAssertEqual(text.string, expected)
    }
}


// MARK: - Private
//
private extension NSAttributedString {

    /// Indicates if the specified atribute (Key / Value) is contained *EXCLUSIVELY* in the specified range.
    ///
    func isAttributeContainedExclusively(in range: NSRange, key: Key, value: NSObject) -> Bool {
        for index in 0 ..< length {
            let retrievedValue = attribute(key, at: index, effectiveRange: nil) as? NSObject
            let shouldContainWatermark = NSLocationInRange(index, range)
            let containsWatermark = retrievedValue == value

            if shouldContainWatermark && containsWatermark || !shouldContainWatermark && !containsWatermark {
                continue
            }

            return false
        }

        return true
    }
}
