import Testing
import UIKit
@testable import WooCommerce

struct TracksProviderHorizontalSizeClassTests {

    private let sut = TracksProvider()
    private let key = "horizontal_size_class"

    @Test func test_addHorizontalSizeClass_when_regular_then_adds_regular_value() {
        // When
        let result = sut.addHorizontalSizeClass(to: [:], sizeClass: .regular)

        // Then
        #expect(result?[key] as? String == "regular")
    }

    @Test func test_addHorizontalSizeClass_when_compact_then_adds_compact_value() {
        // When
        let result = sut.addHorizontalSizeClass(to: [:], sizeClass: .compact)

        // Then
        #expect(result?[key] as? String == "compact")
    }

    @Test func test_addHorizontalSizeClass_when_unspecified_then_does_not_add_property() {
        // When
        let withProperties = sut.addHorizontalSizeClass(to: ["a": 1], sizeClass: .unspecified)
        let withoutProperties = sut.addHorizontalSizeClass(to: nil, sizeClass: .unspecified)

        // Then
        #expect(withProperties?[key] == nil)
        #expect(withProperties?["a"] as? Int == 1)
        #expect(withoutProperties == nil)
    }

    @Test func test_addHorizontalSizeClass_when_property_already_present_then_keeps_existing_value() {
        // Given — an event that already carries its own horizontal_size_class (e.g. product/order factories)
        let existing: [AnyHashable: Any] = [key: "regular"]

        // When — the cached layout differs
        let result = sut.addHorizontalSizeClass(to: existing, sizeClass: .compact)

        // Then — the event's own value wins
        #expect(result?[key] as? String == "regular")
    }

    @Test func test_addHorizontalSizeClass_preserves_other_properties() {
        // Given
        let existingProperties: [AnyHashable: Any] = ["some_int_property": 2, "some_bool_property": false]

        // When
        let result = sut.addHorizontalSizeClass(to: existingProperties, sizeClass: .regular)

        // Then
        #expect(result?["some_int_property"] as? Int == 2)
        #expect(result?["some_bool_property"] as? Bool == false)
        #expect(result?[key] as? String == "regular")
    }

    @Test func test_addHorizontalSizeClass_when_nil_properties_and_concrete_sizeClass_then_returns_only_layout() {
        // When
        let result = sut.addHorizontalSizeClass(to: nil, sizeClass: .compact)

        // Then
        #expect(result?.count == 1)
        #expect(result?[key] as? String == "compact")
    }
}
