import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductVariationDetailSummaryTests {
    @Test
    func test_make_when_variation_has_attributes_then_each_attribute_carries_name_and_option() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(33),
            "attributes": .array([
                .object(["id": .int(7), "name": .string("Color"), "option": .string("Red")])
            ])
        ])

        // When
        let summary = ProductVariationDetailSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let attrs) = fields["attributes"],
              case .object(let first) = attrs.first else {
            Issue.record("expected attributes")
            return
        }
        #expect(first["name"] == .string("Color"))
        #expect(first["option"] == .string("Red"))
    }

    @Test
    func test_make_when_variation_description_exceeds_500_chars_then_value_is_truncated_and_flag_is_true() {
        // Given
        let long = String(repeating: "z", count: 700)
        let entity = AnyCodableJSON.object(["id": .int(1), "description": .string(long)])

        // When
        let summary = ProductVariationDetailSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .string(let projected) = fields["description"] else {
            Issue.record("expected description")
            return
        }
        #expect(projected.count == 500)
        #expect(fields["description_truncated"] == .bool(true))
    }

    @Test
    func test_make_when_variation_has_dimensions_then_length_width_height_are_emitted() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(1),
            "dimensions": .object([
                "length": .string("1"),
                "width": .string("2"),
                "height": .string("3")
            ])
        ])

        // When
        let summary = ProductVariationDetailSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .object(let dim) = fields["dimensions"] else {
            Issue.record("expected dimensions")
            return
        }
        #expect(dim["length"] == .string("1"))
        #expect(dim["width"] == .string("2"))
        #expect(dim["height"] == .string("3"))
    }

    @Test
    func test_make_when_variation_has_image_then_image_is_projected_with_src() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(1),
            "image": .object(["id": .int(99), "src": .string("https://example.com/v.jpg")])
        ])

        // When
        let summary = ProductVariationDetailSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .object(let image) = fields["image"] else {
            Issue.record("expected image")
            return
        }
        #expect(image["src"] == .string("https://example.com/v.jpg"))
    }

    @Test
    func test_make_when_variation_has_no_attributes_then_attributes_is_empty_array() {
        // Given
        let entity = AnyCodableJSON.object(["id": .int(1)])

        // When
        let summary = ProductVariationDetailSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["attributes"] == .array([]))
    }
}
