import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct DefaultConfirmationPreviewBuilderTests {

    // MARK: - Unknown tool

    @Test
    func test_build_when_unknown_tool_then_returns_nil() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: "future_unknown_tool",
                                    arguments: "{}",
                                    snapshot: nil)

        // Then
        #expect(preview == nil)
    }

    // MARK: - Orders update

    @Test
    func test_build_when_orders_update_status_only_with_no_snapshot_then_emits_field_without_prior() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42,"status":"pending"}"#,
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == false)
        #expect(unwrapped.fields.count == 1)
        #expect(unwrapped.fields.first?.name == "status")
        #expect(unwrapped.fields.first?.value == .raw("Pending"))
        #expect(unwrapped.fields.first?.priorValue == nil)
    }

    @Test
    func test_build_when_orders_update_status_only_with_snapshot_then_emits_priorValue_and_emails_customer_suffix() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["status": .raw("processing")])

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42,"status":"completed"}"#,
                                    snapshot: snapshot)

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first)
        #expect(field.name == "status")
        #expect(field.priorValue == .raw("Processing"))
        guard case .localized(let resource, let args) = field.value else {
            Issue.record("expected localized status value with emails-customer suffix, got \(field.value)")
            return
        }
        #expect(String(describing: resource).contains("emails_customer"))
        #expect(args == [.raw("Completed")])
    }

    @Test
    func test_build_when_orders_update_status_and_snapshot_differs_then_priorValue_is_set() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["status": .raw("pending")])

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42,"status":"processing"}"#,
                                    snapshot: snapshot)

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.fields.first?.priorValue == .raw("Pending"))
    }

    @Test
    func test_build_when_orders_update_status_on_hold_then_field_value_uses_human_label() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42,"status":"on-hold"}"#,
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first)
        guard case .localized(_, let args) = field.value else {
            Issue.record("expected localized status value with emails-customer suffix, got \(field.value)")
            return
        }
        #expect(args == [.raw("On hold")])
    }

    @Test
    func test_build_when_orders_update_prior_equals_new_then_priorValue_is_nil() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["status": .raw("processing")])

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42,"status":"processing"}"#,
                                    snapshot: snapshot)

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.fields.first?.priorValue == nil)
    }

    @Test
    func test_build_when_orders_update_with_email_and_note_then_includes_all_fields() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"status":"processing","customer_note":"Thanks","billing_email":"a@b.c"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let names = unwrapped.fields.map(\.name)
        #expect(names == ["status", "customer_note", "billing_email"])
    }

    @Test
    func test_build_when_orders_update_status_and_customer_note_with_snapshot_then_status_field_has_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["status": .raw("completed")])

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"status":"pending","customer_note":"Hi"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let statusField = try #require(unwrapped.fields.first(where: { $0.name == "status" }))
        #expect(statusField.priorValue == .raw("Completed"))
        #expect(unwrapped.fields.contains(where: { $0.name == "customer_note" }))
    }

    @Test
    func test_build_when_orders_update_status_and_billing_email_with_snapshot_then_both_fields_have_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: [
            "status": .raw("processing"),
            "billing_email": .raw("old@example.com")
        ])

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"status":"completed","billing_email":"new@example.com"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let statusField = try #require(unwrapped.fields.first(where: { $0.name == "status" }))
        #expect(statusField.priorValue == .raw("Processing"))
        let emailField = try #require(unwrapped.fields.first(where: { $0.name == "billing_email" }))
        #expect(emailField.priorValue == .raw("old@example.com"))
    }

    @Test
    func test_build_when_orders_update_has_customer_note_under_160_chars_then_field_value_is_raw_note_without_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"customer_note":"Thanks for the order"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "customer_note" }))
        #expect(field.value == .raw("Thanks for the order"))
        #expect(field.priorValue == nil)
    }

    @Test
    func test_build_when_orders_update_has_customer_note_at_exactly_160_chars_then_value_is_unchanged_without_ellipsis() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let exact = String(repeating: "a", count: 160)

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"customer_note":"\#(exact)"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "customer_note" }))
        #expect(field.value == .raw(exact))
    }

    @Test
    func test_build_when_orders_update_has_customer_note_over_160_chars_then_field_value_is_first_160_chars_plus_ellipsis() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let long = String(repeating: "a", count: 200)

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"customer_note":"\#(long)"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "customer_note" }))
        let expected = String(repeating: "a", count: 160) + "..."
        #expect(field.value == .raw(expected))
    }

    @Test
    func test_build_when_orders_update_has_customer_note_with_snapshot_present_then_priorValue_is_still_omitted() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["customer_note": .raw("previous note")])

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"customer_note":"Thanks"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "customer_note" }))
        #expect(field.priorValue == nil)
    }

    @Test
    func test_build_when_orders_bulk_update_has_customer_note_then_field_renders_as_truncated_note_with_no_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let long = String(repeating: "b", count: 200)

        // When
        let preview = builder.build(
            toolName: OrdersBulkUpdateTool.name,
            arguments: #"{"ids":[1,2],"patch":{"customer_note":"\#(long)"}}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "customer_note" }))
        let expected = String(repeating: "b", count: 160) + "..."
        #expect(field.value == .raw(expected))
        #expect(field.priorValue == nil)
    }

    @Test
    func test_build_when_orders_update_has_billing_email_and_snapshot_then_field_carries_value_and_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["billing_email": .raw("old@example.com")])

        // When
        let preview = builder.build(
            toolName: OrdersUpdateTool.name,
            arguments: #"{"id":42,"billing_email":"new@example.com"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "billing_email" }))
        #expect(field.value == .raw("new@example.com"))
        #expect(field.priorValue == .raw("old@example.com"))
    }

    @Test
    func test_build_when_orders_update_id_only_then_returns_summary_with_no_fields() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42}"#,
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.fields.isEmpty)
        #expect(unwrapped.isBulk == false)
    }

    @Test
    func test_build_when_orders_update_arguments_invalid_then_returns_fallback() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: "{}",
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.fields.isEmpty)
        #expect(unwrapped.isBulk == false)
    }

    // MARK: - Orders bulk update

    @Test
    func test_build_when_orders_bulk_update_then_isBulk_is_true_and_priorValue_never_set() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["status": .raw("pending")])

        // When
        let preview = builder.build(
            toolName: OrdersBulkUpdateTool.name,
            arguments: #"{"ids":[1,2,3],"patch":{"status":"completed"}}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == true)
        #expect(unwrapped.fields.allSatisfy { $0.priorValue == nil })
    }

    // MARK: - Products update

    @Test
    func test_build_when_products_update_then_emits_field_per_changed_attribute() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"id":7,"name":"Cap","regular_price":"24.99","stock_quantity":12,"status":"publish"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let names = unwrapped.fields.map(\.name)
        #expect(names == ["name", "regular_price", "stock_quantity", "status"])
        #expect(unwrapped.fields.first(where: { $0.name == "stock_quantity" })?.value == .raw("12"))
    }

    @Test
    func test_build_when_products_update_multiple_fields_with_snapshot_then_each_field_has_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: [
            "name": .raw("Old name"),
            "regular_price": .raw("9.99"),
            "stock_quantity": .raw("3"),
            "status": .raw("draft")
        ])

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"id":7,"name":"New name","regular_price":"24.99","stock_quantity":12,"status":"publish"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let nameField = try #require(unwrapped.fields.first(where: { $0.name == "name" }))
        #expect(nameField.priorValue == .raw("Old name"))
        let priceField = try #require(unwrapped.fields.first(where: { $0.name == "regular_price" }))
        #expect(priceField.priorValue == .raw("9.99"))
        let stockField = try #require(unwrapped.fields.first(where: { $0.name == "stock_quantity" }))
        #expect(stockField.priorValue == .raw("3"))
        let statusField = try #require(unwrapped.fields.first(where: { $0.name == "status" }))
        #expect(statusField.priorValue == .raw("Draft"))
    }

    @Test
    func test_build_when_products_update_sale_price_empty_then_value_is_off_marker() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: ProductsUpdateTool.name,
                                    arguments: #"{"id":7,"sale_price":""}"#,
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        let saleField = unwrapped.fields.first(where: { $0.name == "sale_price" })
        #expect(saleField != nil)
        if case .localized = saleField?.value {} else {
            Issue.record("expected sale_price value to be a localized off marker")
        }
    }

    // MARK: - Products bulk update

    @Test
    func test_build_when_products_bulk_update_then_isBulk_and_priorValue_never_set() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsBulkUpdateTool.name,
            arguments: #"{"ids":[1,2],"patch":{"status":"draft"}}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == true)
        #expect(unwrapped.fields.allSatisfy { $0.priorValue == nil })
    }

    // MARK: - Product variations update

    @Test
    func test_build_when_product_variation_update_then_includes_variation_fields() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductVariationsUpdateTool.name,
            arguments: #"{"product_id":7,"id":15,"regular_price":"19.99","sku":"CAP-RED","stock_status":"instock"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let names = unwrapped.fields.map(\.name)
        #expect(names == ["regular_price", "stock_status", "sku"])
    }

    @Test
    func test_build_when_product_variations_update_multiple_fields_with_snapshot_then_each_field_has_priorValue() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: [
            "regular_price": .raw("9.99"),
            "stock_status": .raw("instock"),
            "sku": .raw("OLD-SKU"),
            "status": .raw("draft")
        ])

        // When
        let preview = builder.build(
            toolName: ProductVariationsUpdateTool.name,
            arguments: #"{"product_id":7,"id":15,"regular_price":"19.99","stock_status":"outofstock","sku":"NEW-SKU","status":"publish"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let priceField = try #require(unwrapped.fields.first(where: { $0.name == "regular_price" }))
        #expect(priceField.priorValue == .raw("9.99"))
        let stockField = try #require(unwrapped.fields.first(where: { $0.name == "stock_status" }))
        if case .localized(let resource, _) = stockField.priorValue {
            #expect(String(describing: resource).contains("instock"))
        } else {
            Issue.record("expected stock_status priorValue to be a localized resource")
        }
        let skuField = try #require(unwrapped.fields.first(where: { $0.name == "sku" }))
        #expect(skuField.priorValue == .raw("OLD-SKU"))
        let statusField = try #require(unwrapped.fields.first(where: { $0.name == "status" }))
        #expect(statusField.priorValue == .raw("Draft"))
    }

    @Test
    func test_build_when_product_variation_stock_status_outofstock_then_value_is_humanized() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductVariationsUpdateTool.name,
            arguments: #"{"product_id":7,"id":15,"stock_status":"outofstock"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let stockStatus = unwrapped.fields.first(where: { $0.name == "stock_status" })
        if case .localized(let resource, _) = stockStatus?.value {
            #expect(String(describing: resource).contains("outofstock"))
        } else {
            Issue.record("expected stock_status value to be a localized resource")
        }
    }

    @Test
    func test_build_when_product_variation_snapshot_carries_stock_status_then_priorValue_is_humanized() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["stock_status": .raw("instock")])

        // When
        let preview = builder.build(
            toolName: ProductVariationsUpdateTool.name,
            arguments: #"{"product_id":7,"id":15,"stock_status":"outofstock"}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let stockStatus = unwrapped.fields.first(where: { $0.name == "stock_status" })
        if case .localized(let resource, _) = stockStatus?.priorValue {
            #expect(String(describing: resource).contains("instock"))
        } else {
            Issue.record("expected stock_status priorValue to be a localized resource")
        }
    }

    // MARK: - Product variations bulk update

    @Test
    func test_build_when_product_variations_bulk_update_then_no_fields_and_isBulk_true() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductVariationsBulkUpdateTool.name,
            arguments: #"{"product_id":7,"variations":[{"id":15},{"id":16}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == true)
        #expect(unwrapped.fields.isEmpty)
    }

    // MARK: - Summary headline shape

    @Test
    func test_build_when_orders_update_then_summary_does_not_include_field_values() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":1234,"status":"pending"}"#,
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        let summary = unwrapped.summary.flattened()
        #expect(summary == "Update order #1234")
        #expect(!summary.contains("Pending"))
        #expect(!summary.contains("->"))
        #expect(unwrapped.fields.contains(where: { $0.name == "status" }))
    }

    @Test
    func test_build_when_products_update_then_summary_does_not_include_field_values() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"id":12,"regular_price":"24.99","status":"publish"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let summary = unwrapped.summary.flattened()
        #expect(summary == "Update product #12")
        #expect(!summary.contains("24.99"))
        #expect(!summary.contains("Publish"))
        #expect(unwrapped.fields.contains(where: { $0.name == "regular_price" }))
    }

    @Test
    func test_build_when_product_variations_update_then_summary_does_not_include_field_values() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductVariationsUpdateTool.name,
            arguments: #"{"product_id":7,"id":15,"regular_price":"19.99","sku":"CAP-RED"}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let summary = unwrapped.summary.flattened()
        #expect(summary == "Update variation #15 of product #7")
        #expect(!summary.contains("19.99"))
        #expect(!summary.contains("CAP-RED"))
        #expect(unwrapped.fields.contains(where: { $0.name == "regular_price" }))
    }

    // MARK: - Flattened summary regression

    // Regression: the `LocalizedStringResource(defaultValue:)` interpolation
    // syntax `\(placeholder: .object)` rendered as the literal string `(null)`
    // when read via `String(localized:)`, which made the production card
    // surface "Update order #(null)" instead of "Update order #42".
    // Pin every summary template flattens to a substituted string with no `(null)`.

    @Test
    func test_build_when_orders_update_then_summary_flattened_substitutes_args() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: OrdersUpdateTool.name,
                                    arguments: #"{"id":42,"status":"pending"}"#,
                                    snapshot: nil)

        // Then
        let summary = try #require(preview).summary.flattened()
        #expect(!summary.contains("(null)"))
        #expect(summary.contains("42"))
    }

    @Test
    func test_build_when_orders_bulk_update_then_summary_flattened_substitutes_count() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: OrdersBulkUpdateTool.name,
            arguments: #"{"ids":[1,2,3],"patch":{"status":"completed"}}"#,
            snapshot: nil
        )

        // Then
        let summary = try #require(preview).summary.flattened()
        #expect(!summary.contains("(null)"))
        #expect(summary.contains("3"))
    }

    @Test
    func test_build_when_product_variations_update_then_summary_flattened_substitutes_args() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductVariationsUpdateTool.name,
            arguments: #"{"product_id":7,"id":15,"regular_price":"19.99"}"#,
            snapshot: nil
        )

        // Then
        let summary = try #require(preview).summary.flattened()
        #expect(!summary.contains("(null)"))
        #expect(summary.contains("15"))
        #expect(summary.contains("7"))
    }
}
