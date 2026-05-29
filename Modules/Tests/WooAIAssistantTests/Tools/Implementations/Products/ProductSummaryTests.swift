import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductSummaryTests {
    @Test
    func test_make_when_entity_has_multiple_images_then_summary_keeps_first_three_images() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(101),
            "name": .string("Hoodie"),
            "images": .array([
                .object(["id": .int(1), "src": .string("https://example.com/1.jpg")]),
                .object(["id": .int(2), "src": .string("https://example.com/2.jpg")]),
                .object(["id": .int(3), "src": .string("https://example.com/3.jpg")]),
                .object(["id": .int(4), "src": .string("https://example.com/4.jpg")])
            ])
        ])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .array(let images) = fields["images"] else {
            Issue.record("expected images array on summary")
            return
        }
        #expect(images.count == 3)
        #expect(fields["images_truncated"] == .bool(true))
    }

    @Test
    func test_product_summary_when_categories_exceed_five_then_only_five_returned_and_truncated_flag_is_true() {
        // Given
        let categories = (1...7).map { idx in
            AnyCodableJSON.object(["id": .int(Int64(idx)), "name": .string("c\(idx)"), "slug": .string("c\(idx)")])
        }
        let entity = AnyCodableJSON.object(["id": .int(1), "categories": .array(categories)])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let projected) = fields["categories"] else {
            Issue.record("expected categories array")
            return
        }
        #expect(projected.count == 5)
        #expect(fields["categories_count"] == .int(7))
        #expect(fields["categories_truncated"] == .bool(true))
    }

    @Test
    func test_product_summary_when_description_exceeds_500_chars_then_value_is_truncated_and_flag_is_true() {
        // Given
        let long = String(repeating: "x", count: 600)
        let entity = AnyCodableJSON.object(["id": .int(1), "description": .string(long)])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .string(let projected) = fields["description"] else {
            Issue.record("expected description string")
            return
        }
        #expect(projected.count == 500)
        #expect(fields["description_truncated"] == .bool(true))
    }

    @Test
    func test_product_summary_when_short_description_is_short_then_truncated_flag_is_absent() {
        // Given
        let entity = AnyCodableJSON.object(["id": .int(1), "short_description": .string("Cozy")])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["short_description"] == .string("Cozy"))
        #expect(fields["short_description_truncated"] == nil)
    }

    @Test
    func test_product_summary_when_attributes_present_then_options_array_is_carried_through() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(1),
            "attributes": .array([
                .object([
                    "id": .int(7),
                    "name": .string("Color"),
                    "visible": .bool(true),
                    "variation": .bool(true),
                    "options": .array([.string("Red"), .string("Blue")])
                ])
            ])
        ])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let attrs) = fields["attributes"],
              case .object(let first) = attrs.first else {
            Issue.record("expected attributes array")
            return
        }
        #expect(first["options"] == .array([.string("Red"), .string("Blue")]))
        #expect(first["visible"] == .bool(true))
        #expect(first["variation"] == .bool(true))
    }

    @Test
    func test_product_summary_when_images_exceed_three_then_only_three_returned_and_truncated_flag_is_true() {
        // Given
        let images = (1...5).map { idx in
            AnyCodableJSON.object(["id": .int(Int64(idx)), "src": .string("u\(idx)")])
        }
        let entity = AnyCodableJSON.object(["id": .int(1), "images": .array(images)])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .array(let projected) = fields["images"] else {
            Issue.record("expected images array")
            return
        }
        #expect(projected.count == 3)
        #expect(fields["images_truncated"] == .bool(true))
    }

    @Test
    func test_product_summary_when_dimensions_present_then_length_width_height_are_emitted_as_strings() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(1),
            "dimensions": .object([
                "length": .string("10"),
                "width": .string("20"),
                "height": .string("30")
            ])
        ])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .object(let dim) = fields["dimensions"] else {
            Issue.record("expected dimensions object")
            return
        }
        #expect(dim["length"] == .string("10"))
        #expect(dim["width"] == .string("20"))
        #expect(dim["height"] == .string("30"))
    }

    @Test
    func test_product_summary_when_variable_product_has_variations_array_then_variation_ids_truncated_at_twenty_and_count_reflects_total() {
        // Given
        let ids = (1...25).map { AnyCodableJSON.int(Int64($0)) }
        let entity = AnyCodableJSON.object(["id": .int(1), "variations": .array(ids)])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let projected) = fields["variation_ids"] else {
            Issue.record("expected variation_ids array")
            return
        }
        #expect(projected.count == 20)
        #expect(fields["variations_count"] == .int(25))
        #expect(fields["variation_ids_truncated"] == .bool(true))
    }

    @Test
    func test_product_summary_when_simple_product_then_parent_id_is_zero_and_variation_ids_is_empty_array() {
        // Given
        let entity = AnyCodableJSON.object(["id": .int(1), "parent_id": .int(0), "type": .string("simple")])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["parent_id"] == .int(0))
        #expect(fields["variation_ids"] == .array([]))
        #expect(fields["variations_count"] == .int(0))
    }

    @Test
    func test_product_summary_when_cross_and_upsell_ids_present_then_arrays_are_emitted() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(1),
            "cross_sell_ids": .array([.int(7), .int(8)]),
            "upsell_ids": .array([.int(9)])
        ])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["cross_sell_ids"] == .array([.int(7), .int(8)]))
        #expect(fields["upsell_ids"] == .array([.int(9)]))
    }

    @Test
    func test_listRow_when_entity_has_images_then_first_image_is_projected_as_image_field() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(1),
            "images": .array([
                .object(["id": .int(11), "src": .string("a")]),
                .object(["id": .int(12), "src": .string("b")])
            ])
        ])

        // When
        let summary = ProductSummary.listRow(from: entity)

        // Then
        guard case .object(let fields) = summary, case .object(let image) = fields["image"] else {
            Issue.record("expected image object")
            return
        }
        #expect(image["src"] == .string("a"))
        #expect(fields["images"] == nil)
    }
}
