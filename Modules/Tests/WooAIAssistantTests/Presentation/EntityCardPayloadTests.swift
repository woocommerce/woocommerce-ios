import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct EntityCardPayloadTests {

    // MARK: - OrderCardPayload

    @Test
    func test_decodeOrder_when_payload_has_full_fields_then_decodes_all_values() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(3551),
            "number": .string("3551"),
            "status": .string("processing"),
            "total": .string("142.50"),
            "currency": .string("USD"),
            "date_created": .string("2026-04-12T10:00:00"),
            "customer_name": .string("Jane Doe"),
            "customer_email": .string("jane@example.com"),
            "customer_id": .int(11)
        ])

        // When
        let order = EntityCardPayload.decodeOrder(payload)

        // Then
        #expect(order?.id == 3551)
        #expect(order?.number == "3551")
        #expect(order?.status == "processing")
        #expect(order?.total == "142.50")
        #expect(order?.currency == "USD")
        #expect(order?.customerName == "Jane Doe")
        #expect(order?.customerID == 11)
    }

    @Test
    func test_decodeOrder_when_payload_has_only_id_then_other_fields_are_nil() {
        // Given
        let payload = AnyCodableJSON.object(["id": .int(7)])

        // When
        let order = EntityCardPayload.decodeOrder(payload)

        // Then
        #expect(order?.id == 7)
        #expect(order?.number == nil)
        #expect(order?.status == nil)
        #expect(order?.customerName == nil)
    }

    @Test
    func test_decodeOrder_when_payload_has_unknown_fields_then_decode_still_succeeds() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(7),
            "unknown_field": .string("ignored")
        ])

        // When
        let order = EntityCardPayload.decodeOrder(payload)

        // Then
        #expect(order?.id == 7)
    }

    @Test
    func test_orderCardPayload_isEmpty_when_no_fields_set_then_returns_true() {
        // Given
        let order = OrderCardPayload()

        // Then
        #expect(order.isEmpty == true)
    }

    @Test
    func test_orderCardPayload_isEmpty_when_id_is_set_then_returns_false() {
        // Given
        let order = OrderCardPayload(id: 5)

        // Then
        #expect(order.isEmpty == false)
    }

    @Test
    func test_decodeOrderRows_when_rows_is_empty_then_returns_empty() {
        // Given
        let payload = AnyCodableJSON.object([
            "count": .int(0),
            "rows": .array([])
        ])

        // When
        let rows = EntityCardPayload.decodeOrderRows(payload)

        // Then
        #expect(rows.isEmpty)
    }

    @Test
    func test_decodeOrderRows_when_rows_has_entries_then_returns_typed_rows() {
        // Given
        let payload = AnyCodableJSON.object([
            "rows": .array([
                .object(["id": .int(1), "number": .string("1")]),
                .object(["id": .int(2), "number": .string("2")])
            ])
        ])

        // When
        let rows = EntityCardPayload.decodeOrderRows(payload)

        // Then
        #expect(rows.count == 2)
        #expect(rows[0].id == 1)
        #expect(rows[1].number == "2")
    }

    // MARK: - ProductCardPayload

    @Test
    func test_decodeProduct_when_payload_has_image_then_firstImageURL_is_built() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(101),
            "name": .string("Hoodie"),
            "images": .array([
                .object(["src": .string("https://example.com/hoodie.png")])
            ])
        ])

        // When
        let product = EntityCardPayload.decodeProduct(payload)

        // Then
        #expect(product?.id == 101)
        #expect(product?.name == "Hoodie")
        #expect(product?.firstImageURL?.absoluteString == "https://example.com/hoodie.png")
    }

    @Test
    func test_decodeProduct_when_payload_has_no_images_then_firstImageURL_is_nil() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(101),
            "name": .string("Hoodie")
        ])

        // When
        let product = EntityCardPayload.decodeProduct(payload)

        // Then
        #expect(product?.firstImageURL == nil)
    }

    @Test
    func test_productCardPayload_isEmpty_when_only_id_set_then_returns_false() {
        // Given
        let product = ProductCardPayload(id: 1)

        // Then
        #expect(product.isEmpty == false)
    }

    // MARK: - CustomerCardPayload

    @Test
    func test_decodeCustomer_when_payload_has_first_and_last_name_then_displayName_combines() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(7),
            "first_name": .string("Jane"),
            "last_name": .string("Doe"),
            "email": .string("jane@example.com"),
            "orders_count": .int(3)
        ])

        // When
        let customer = EntityCardPayload.decodeCustomer(payload)

        // Then
        #expect(customer?.id == 7)
        #expect(customer?.displayName == "Jane Doe")
        #expect(customer?.email == "jane@example.com")
        #expect(customer?.ordersCount == 3)
    }

    @Test
    func test_decodeCustomer_when_only_email_set_then_displayName_falls_back_to_email() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(7),
            "email": .string("only@example.com")
        ])

        // When
        let customer = EntityCardPayload.decodeCustomer(payload)

        // Then
        #expect(customer?.displayName == "only@example.com")
    }

    @Test
    func test_decodeCustomerRows_when_payload_uses_matches_key_then_decodes() {
        // Given
        let payload = AnyCodableJSON.object([
            "matches": .array([
                .object(["id": .int(1), "first_name": .string("Alex")]),
                .object(["id": .int(2), "first_name": .string("Sam")])
            ])
        ])

        // When
        let rows = EntityCardPayload.decodeCustomerRows(payload)

        // Then
        #expect(rows.count == 2)
        #expect(rows[0].firstName == "Alex")
    }

    // MARK: - ProductVariationCardPayload

    @Test
    func test_decodeProductVariation_when_payload_has_parent_id_then_decodes() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(202),
            "parent_id": .int(99),
            "name": .string("Small / Red"),
            "price": .string("19.00")
        ])

        // When
        let variation = EntityCardPayload.decodeProductVariation(payload)

        // Then
        #expect(variation?.id == 202)
        #expect(variation?.parentID == 99)
    }

    // MARK: - visible

    @Test
    func test_visible_when_rows_exceed_limit_then_caps_at_limit() {
        // Given
        let rows = (0..<10).map { OrderCardPayload(id: Int64($0)) }

        // When
        let visible = EntityCardPayload.visible(rows)

        // Then
        #expect(visible.count == entityCardVisibleRowLimit)
    }

    @Test
    func test_visible_when_rows_below_limit_then_returns_all() {
        // Given
        let rows = (0..<2).map { OrderCardPayload(id: Int64($0)) }

        // When
        let visible = EntityCardPayload.visible(rows)

        // Then
        #expect(visible.count == 2)
    }
}
