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
        #expect(unwrapped.fields.first?.value == .raw("Pending Payment"))
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
        #expect(unwrapped.fields.first?.priorValue == .raw("Pending Payment"))
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
    func test_build_when_products_update_single_then_emits_combined_changed_keys_and_isBulk_false() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"regular_price":"24.99","status":"publish"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == false)
        let names = unwrapped.fields.map(\.name)
        #expect(names == ["regular_price", "status"])
        #expect(unwrapped.bulkEntries.map(\.id) == [12])
    }

    @Test
    func test_build_when_products_update_multiple_then_isBulk_true_and_keys_unioned() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":1},"regular_price":"10"},{"target":{"kind":"product","id":2},"sale_price":"5"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == true)
        let names = Set(unwrapped.fields.map(\.name))
        #expect(names == ["sale_price", "regular_price"])
        #expect(unwrapped.bulkEntries.map(\.id) == [1, 2])
    }

    @Test
    func test_build_when_products_update_snapshot_carries_bulk_entries_then_uses_them() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: [:],
                                            bulkEntries: [
                                                ConfirmationBulkEntry(id: 1, displayName: "Hoodie"),
                                                ConfirmationBulkEntry(id: 2, displayName: "Tee")
                                            ])

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":1},"sale_price":"5"},{"target":{"kind":"product","id":2},"sale_price":"5"}]}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.bulkEntries.compactMap(\.displayName) == ["Hoodie", "Tee"])
    }

    @Test
    func test_build_when_products_update_single_then_summary_flattened_is_update_1_product() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"regular_price":"24.99"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 1 product")
    }

    @Test
    func test_build_when_products_update_multiple_then_summary_flattened_is_update_2_products() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":1},"sale_price":"5"},{"target":{"kind":"product","id":2},"sale_price":"5"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 2 products")
    }

    @Test
    func test_build_when_products_update_sets_name_stock_status_sku_then_all_three_render_as_fields() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"name":"Renamed","stock_status":"outofstock","sku":"TEE-1"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let names = unwrapped.fields.map(\.name)
        #expect(names == ["name", "stock_status", "sku"])
    }

    @Test
    func test_build_when_products_update_invalid_arguments_then_returns_fallback() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(toolName: ProductsUpdateTool.name,
                                    arguments: #"{}"#,
                                    snapshot: nil)

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.fields.isEmpty)
        #expect(unwrapped.summary.flattened() == "Update products")
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
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"regular_price":"24.99","status":"publish"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let summary = unwrapped.summary.flattened()
        #expect(!summary.contains("24.99"))
        #expect(!summary.contains("Publish"))
        #expect(unwrapped.fields.contains(where: { $0.name == "regular_price" }))
    }

    // MARK: - Flattened summary regression

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
    func test_build_when_products_update_then_summary_flattened_substitutes_count() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"5"},{"target":{"kind":"product","id":8},"sale_price":"5"}]}"#,
            snapshot: nil
        )

        // Then
        let summary = try #require(preview).summary.flattened()
        #expect(!summary.contains("(null)"))
        #expect(summary.contains("2"))
    }

    // MARK: - Products update concrete values

    @Test
    func test_build_when_products_update_sale_price_then_summary_includes_formatted_price() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"sale_price":"19.99"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(field.value == .raw("19.99"))
        #expect(unwrapped.flattenedSummary().contains("19.99"))
    }

    @Test
    func test_build_when_products_update_sale_price_is_empty_then_summary_includes_cleared_marker() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"sale_price":""}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(field.value.flattened() == "Cleared")
    }

    @Test
    func test_build_when_products_update_status_then_summary_includes_humanized_status() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"status":"draft"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "status" }))
        #expect(field.value == .raw("Draft"))
    }

    @Test
    func test_build_when_products_update_status_publish_then_value_is_humanized_to_published() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"status":"publish"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "status" }))
        #expect(field.value == .raw("Published"))
    }

    @Test
    func test_build_when_products_update_stock_status_then_summary_includes_humanized_label() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"stock_status":"outofstock"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "stock_status" }))
        #expect(field.value == .raw("Out of stock"))
    }

    @Test
    func test_build_when_products_update_stock_quantity_then_value_is_decimal_string() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"stock_quantity":5}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "stock_quantity" }))
        #expect(field.value == .raw("5"))
    }

    @Test
    func test_build_when_products_update_name_and_sku_then_values_render_as_raw() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"name":"Premium Cashmere Scarf","sku":"PCS-BLK-01"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let nameField = try #require(unwrapped.fields.first(where: { $0.name == "name" }))
        #expect(nameField.value == .raw("Premium Cashmere Scarf"))
        let skuField = try #require(unwrapped.fields.first(where: { $0.name == "sku" }))
        #expect(skuField.value == .raw("PCS-BLK-01"))
    }

    @Test
    func test_build_when_products_update_regular_price_then_field_value_is_raw_decimal_string() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"regular_price":"29.99"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "regular_price" }))
        #expect(field.value == .raw("29.99"))
    }

    @Test
    func test_build_when_products_update_multi_entry_then_summary_includes_count_and_field_union() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":1},"regular_price":"15","status":"draft"},
              {"target":{"kind":"product","id":2},"sale_price":"9.99"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == true)
        #expect(unwrapped.summary.flattened() == "Update 2 products")
        let names = unwrapped.fields.map(\.name)
        #expect(Set(names) == ["regular_price", "status", "sale_price"])
    }

    @Test
    func test_build_when_products_update_field_values_diverge_then_renders_varies_per_item() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":1},"sale_price":"19.99"},{"target":{"kind":"product","id":2},"sale_price":"5.00"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let saleField = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(saleField.value.flattened() == "varies per item")
    }

    @Test
    func test_build_when_products_update_percent_discount_then_summary_includes_percent() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"percent_discount":10}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "percent_discount" }))
        #expect(field.value.flattened() == "10% off")
    }

    @Test
    func test_build_when_products_update_field_set_by_some_entries_then_renders_varies_per_item() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":1},"sale_price":"9.99"},
              {"target":{"kind":"product","id":2},"name":"Tee"},
              {"target":{"kind":"product","id":3},"name":"Shirt"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let saleField = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(saleField.value.flattened() == "varies per item")
    }

    @Test
    func test_productField_when_values_diverge_then_perEntryValues_populated_per_id() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":3859},"stock_quantity":10},
              {"target":{"kind":"product","id":3860},"stock_quantity":5},
              {"target":{"kind":"product","id":3861},"stock_quantity":8}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "stock_quantity" }))
        let perEntry = try #require(field.perEntryValues)
        #expect(perEntry[3859] == .raw("10"))
        #expect(perEntry[3860] == .raw("5"))
        #expect(perEntry[3861] == .raw("8"))
    }

    @Test
    func test_productField_when_values_uniform_then_perEntryValues_nil() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":1},"sale_price":"10.00"},{"target":{"kind":"product","id":2},"sale_price":"10.00"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(field.perEntryValues == nil)
    }

    @Test
    func test_productField_when_some_entries_omit_field_then_still_renders_perEntryValues_only_for_set_entries() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":1},"sale_price":"9.99"},
              {"target":{"kind":"product","id":2},"name":"Tee"},
              {"target":{"kind":"product","id":3},"name":"Shirt"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let saleField = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(saleField.value.flattened() == "varies per item")
        let perEntry = try #require(saleField.perEntryValues)
        #expect(perEntry[1] == .raw("9.99"))
        #expect(perEntry[2] == nil)
        #expect(perEntry[3] == nil)
    }

    @Test
    func test_build_when_scoped_fanout_with_snapshot_count_then_summary_names_parent_and_count() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(
            currentValues: [:],
            bulkEntries: [ConfirmationBulkEntry(id: 821, displayName: "Hoodie")],
            parentVariationCounts: [821: 12]
        )

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":821,"scope":"all_variations"},"percent_discount":10}]}
            """#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Apply changes to all 12 variations of Hoodie")
    }

    @Test
    func test_build_when_scoped_fanout_without_snapshot_count_then_summary_degrades_gracefully() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(
            currentValues: [:],
            bulkEntries: [ConfirmationBulkEntry(id: 821, displayName: "Hoodie")]
        )

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":821,"scope":"all_variations"},"percent_discount":10}]}
            """#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Apply changes to all variations of Hoodie")
    }

    @Test
    func test_build_when_scoped_fanout_without_snapshot_then_summary_uses_parent_id_token() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":821,"scope":"all_variations"},"percent_discount":10}]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Apply changes to all variations of #821")
    }

    @Test
    func test_build_when_two_scoped_fanouts_with_counts_then_summary_aggregates_across_parents() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(
            currentValues: [:],
            bulkEntries: [
                ConfirmationBulkEntry(id: 821, displayName: "Hoodie"),
                ConfirmationBulkEntry(id: 822, displayName: "Tee")
            ],
            parentVariationCounts: [821: 8, 822: 4]
        )

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":821,"scope":"all_variations"},"percent_discount":10},
              {"target":{"kind":"product","id":822,"scope":"all_variations"},"percent_discount":10}
            ]}
            """#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Apply changes to 12 variations across 2 parents")
    }

    @Test
    func test_productsUpdate_bulk_entries_use_variation_names_when_available() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(
            currentValues: [:],
            bulkEntries: [
                ConfirmationBulkEntry(id: 821, displayName: "Hoodie", subEntries: [
                    ConfirmationBulkEntry(id: 901, displayName: "Hoodie - Red, Small"),
                    ConfirmationBulkEntry(id: 902, displayName: "Hoodie - Red, Medium")
                ])
            ],
            parentVariationCounts: [821: 2]
        )

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":821,"scope":"all_variations"},"percent_discount":10}]}
            """#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let parent = try #require(unwrapped.bulkEntries.first)
        #expect(parent.id == 821)
        #expect(parent.displayName == "Hoodie")
        #expect(parent.subEntries.map(\.displayName) == ["Hoodie - Red, Small", "Hoodie - Red, Medium"])
    }

    @Test
    func test_build_when_products_update_field_values_uniform_then_renders_value() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":1},"sale_price":"9.99"},{"target":{"kind":"product","id":2},"sale_price":"9.99"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let saleField = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(saleField.value == .raw("9.99"))
    }

    @Test
    func test_build_when_single_product_update_and_snapshot_differs_then_priorValue_is_set() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["sale_price": .raw("1000")],
                                            bulkEntries: [ConfirmationBulkEntry(id: 7)])

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"15"}]}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(field.value == .raw("15"))
        #expect(field.priorValue == .raw("1000"))
    }

    @Test
    func test_build_when_single_product_update_and_snapshot_matches_then_priorValue_is_nil() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["sale_price": .raw("15")],
                                            bulkEntries: [ConfirmationBulkEntry(id: 7)])

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"15"}]}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(field.priorValue == nil)
    }

    @Test
    func test_build_when_bulk_product_update_then_priorValue_is_nil_even_with_snapshot() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()
        let snapshot = ConfirmationSnapshot(currentValues: ["sale_price": .raw("1000")],
                                            bulkEntries: [ConfirmationBulkEntry(id: 7),
                                                          ConfirmationBulkEntry(id: 8)])

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"15"},{"target":{"kind":"product","id":8},"sale_price":"15"}]}"#,
            snapshot: snapshot
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.isBulk == true)
        let field = try #require(unwrapped.fields.first(where: { $0.name == "sale_price" }))
        #expect(field.priorValue == nil)
    }

    // MARK: - Summary kind counts

    @Test
    func test_build_when_single_variation_target_then_summary_says_update_one_variation() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"variation","id":58,"parent_id":41},"sale_price":"5"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 1 variation")
    }

    @Test
    func test_build_when_mixed_products_and_variations_then_summary_counts_each_kind() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":1},"sale_price":"5"},
              {"target":{"kind":"product","id":2},"sale_price":"5"},
              {"target":{"kind":"variation","id":58,"parent_id":41},"sale_price":"5"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 2 products and 1 variation")
    }

    @Test
    func test_productsUpdate_summary_text_grammar_when_single_product_no_variations_then_singular() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":12},"sale_price":"5"}]}"#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 1 product")
    }

    @Test
    func test_productsUpdate_summary_text_grammar_when_single_product_single_variation_then_both_singular() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":1},"sale_price":"5"},
              {"target":{"kind":"variation","id":58,"parent_id":41},"sale_price":"5"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 1 product and 1 variation")
    }

    @Test
    func test_productsUpdate_summary_text_grammar_when_multiple_products_multiple_variations_then_both_plural() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":1},"sale_price":"5"},
              {"target":{"kind":"product","id":2},"sale_price":"5"},
              {"target":{"kind":"product","id":3},"sale_price":"5"},
              {"target":{"kind":"variation","id":58,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":59,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":60,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":61,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":62,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":63,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":64,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":65,"parent_id":41},"sale_price":"5"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        #expect(unwrapped.summary.flattened() == "Update 3 products and 8 variations")
    }

    @Test
    func test_productsUpdate_summary_text_grammar_when_variations_only_then_no_products_in_summary() throws {
        // Given
        let builder = DefaultConfirmationPreviewBuilder()

        // When
        let preview = builder.build(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"variation","id":58,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":59,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":60,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":61,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":62,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":63,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":64,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":65,"parent_id":41},"sale_price":"5"}
            ]}
            """#,
            snapshot: nil
        )

        // Then
        let unwrapped = try #require(preview)
        let summary = unwrapped.summary.flattened()
        #expect(summary == "Update 8 variations")
        #expect(!summary.contains("product"))
    }
}
