
import XCTest

@testable import Networking

/// Tests the concepts of `Copiable`.
///
/// We are using `ProductImage` as a guinea pig only.
///
final class CopiableTests: XCTestCase {

    func testItCanReplaceAllPropertyValues() {
        // Given
        let original = ProductImage(
            imageID: 1_000,
            dateCreated: Date(),
            dateModified: nil,
            src: "__src__",
            name: nil,
            alt: nil
        )

        // When
        let copy = original.copy(
            imageID: 3_000,
            dateCreated: Date(timeIntervalSince1970: 100),
            dateModified: Date(timeIntervalSince1970: 200),
            src: "_src_copy_",
            name: "_name_copy_",
            alt: "_alt_copy_"
        )

        // Then
        XCTAssertEqual(copy.imageID, 3_000)
        XCTAssertEqual(copy.dateCreated, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(copy.dateModified, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(copy.src, "_src_copy_")
        XCTAssertEqual(copy.name, "_name_copy_")
        XCTAssertEqual(copy.alt, "_alt_copy_")
    }

    func testItCanSetNonNilPropertiesBackToNil() {
        // Given
        let original = ProductImage(
            imageID: 1_000,
            dateCreated: Date(timeIntervalSince1970: 900),
            dateModified: Date(timeIntervalSince1970: 700),
            src: "_src_original_",
            name: "_name_original_",
            alt: "_alt_original"
        )

        // When
        let copy = original.copy(name: .some(nil))

        // Then
        XCTAssertNil(copy.name)
    }

    func testWhenPassingNilItWillCopyThePropertyInsteadOfSettingItToNil() {
        // Given
        let original = ProductImage(
            imageID: 1_000,
            dateCreated: Date(timeIntervalSince1970: 900),
            dateModified: Date(timeIntervalSince1970: 700),
            src: "_src_original_",
            name: "_name_original_",
            alt: "_alt_original"
        )

        // When
        let copy = original.copy(name: nil)

        // Then
        XCTAssertEqual(copy.name, "_name_original_")
    }

    func testItCanSetNonNilPropertiesBackToNilUsingAStructValueSource() {
        // Given
        struct ValueSource {
            let alt: String?
        }

        let original = ProductImage(
            imageID: 1_000,
            dateCreated: Date(timeIntervalSince1970: 900),
            dateModified: Date(timeIntervalSince1970: 700),
            src: "_src_original_",
            name: "_name_original_",
            alt: "_alt_original"
        )

        let valueSource = ValueSource(alt: nil)

        XCTAssertNotNil(original.alt)

        // When
        let copy = original.copy(alt: valueSource.alt)

        // Then
        XCTAssertNil(copy.alt)
    }

    func testItCanSetNonNilPropertiesBackToNilUsingAVariableValueSource() {
        // Given
        let original = ProductImage(
            imageID: 1_000,
            dateCreated: Date(timeIntervalSince1970: 900),
            dateModified: Date(timeIntervalSince1970: 700),
            src: "_src_original_",
            name: "_name_original_",
            alt: "_alt_original"
        )

        let valueSource: Date? = nil

        XCTAssertNotNil(original.dateModified)

        // When
        let copy = original.copy(dateModified: valueSource)

        // Then
        XCTAssertNil(copy.dateModified)
    }

    func testItWillLeaveTheUnspecifiedPropertiesUnchanged() {
        // Given
        let original = ProductImage(
            imageID: 1_000,
            dateCreated: Date(timeIntervalSince1970: 900),
            dateModified: Date(timeIntervalSince1970: 700),
            src: "_src_original_",
            name: "_name_original_",
            alt: "_alt_original"
        )

        // When
        let copy = original.copy(imageID: 9_000)

        // Then
        XCTAssertNotEqual(copy, original)

        // Specified properties are changed
        XCTAssertEqual(copy.imageID, 9_000)

        // Unspecified properties are copied
        XCTAssertEqual(copy.dateCreated, original.dateCreated)
        XCTAssertEqual(copy.dateModified, original.dateModified)
        XCTAssertEqual(copy.src, original.src)
        XCTAssertEqual(copy.name, original.name)
        XCTAssertEqual(copy.alt, original.alt)
    }
}
