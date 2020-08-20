import XCTest

@testable import Networking

/// Tests the concepts of the `CopiableProp` and `NullableCopiableProp` in the `copy()` methods.
///
/// We are using `ProductImage` as a guinea pig only.
///
final class CopiableTests: XCTestCase {

    func test_it_can_replace_all_property_values() {
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

    func test_it_can_replace_some_property_values() {
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
            dateCreated: Date(timeIntervalSince1970: 100),
            src: "_src_copy_",
            alt: "_alt_copy_"
        )

        // Then
        XCTAssertEqual(copy.imageID, original.imageID)
        XCTAssertEqual(copy.dateCreated, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(copy.dateModified, original.dateModified)
        XCTAssertEqual(copy.src, "_src_copy_")
        XCTAssertEqual(copy.name, original.name)
        XCTAssertEqual(copy.alt, "_alt_copy_")
    }

    func test_it_can_set_non_nil_properties_back_to_nil_using_some_nil() {
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

    func test_when_passing_nil_it_will_copy_the_property_instead_of_setting_it_to_nil() {
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

    func test_it_can_set_non_nil_properties_back_to_nil_using_a_struct_value_source() {
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

    func test_it_can_set_non_nil_properties_back_to_nil_using_a_variable_value_source() {
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

    func test_it_will_leave_the_unspecified_properties_unchanged() {
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
