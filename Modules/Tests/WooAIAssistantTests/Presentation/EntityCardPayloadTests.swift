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

    @Test
    func test_decodeProduct_when_payload_has_variations_count_then_field_is_decoded() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(101),
            "name": .string("Hoodie"),
            "type": .string("variable"),
            "variations_count": .int(15)
        ])

        // When
        let product = EntityCardPayload.decodeProduct(payload)

        // Then
        #expect(product?.variationsCount == 15)
    }

    @Test
    func test_decodeProduct_when_payload_has_no_variations_count_then_field_is_nil() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(101),
            "name": .string("Hoodie")
        ])

        // When
        let product = EntityCardPayload.decodeProduct(payload)

        // Then
        #expect(product?.variationsCount == nil)
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

    @Test
    func test_decodeProductVariation_when_payload_has_image_then_firstImageURL_is_built() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(202),
            "parent_id": .int(99),
            "image": .object([
                "id": .int(404),
                "src": .string("https://example.com/navy-blue.jpg")
            ])
        ])

        // When
        let variation = EntityCardPayload.decodeProductVariation(payload)

        // Then
        #expect(variation?.firstImageURL?.absoluteString == "https://example.com/navy-blue.jpg")
    }

    @Test
    func test_decodeProductVariation_when_payload_has_no_image_then_firstImageURL_is_nil() {
        // Given
        let payload = AnyCodableJSON.object([
            "id": .int(202),
            "parent_id": .int(99)
        ])

        // When
        let variation = EntityCardPayload.decodeProductVariation(payload)

        // Then
        #expect(variation?.firstImageURL == nil)
    }
}
