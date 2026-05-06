import Foundation
import Testing
@testable import WooAIAssistant

struct CardEntityTests {

    @Test
    func test_decode_OrderCardPayload_from_snake_case_json_then_populates_fields() throws {
        // Given
        let data = Data("""
        {"id": 3551, "number": "3551", "status": "processing", "total": "120.00",
         "currency": "USD", "date_created": "2024-01-02T03:04:05",
         "customer_name": "Jane Doe", "customer_email": "jane@example.com",
         "customer_id": 7, "parent_id": 12}
        """.utf8)

        // When
        let decoded = try JSONDecoder().decode(OrderCardPayload.self, from: data)

        // Then
        #expect(decoded.id == 3551)
        #expect(decoded.dateCreated == "2024-01-02T03:04:05")
        #expect(decoded.customerName == "Jane Doe")
        #expect(decoded.customerID == 7)
        #expect(decoded.parentID == 12)
    }

    @Test
    func test_decode_ProductCardPayload_from_snake_case_json_then_populates_fields() throws {
        // Given
        let data = Data("""
        {"id": 42, "name": "Beanie", "sku": "BEAN-1", "price": "19.99",
         "regular_price": "24.99", "sale_price": "19.99",
         "stock_status": "instock", "stock_quantity": 5,
         "type": "simple", "status": "publish",
         "images": [{"src": "https://example.com/i.jpg"}]}
        """.utf8)

        // When
        let decoded = try JSONDecoder().decode(ProductCardPayload.self, from: data)

        // Then
        #expect(decoded.id == 42)
        #expect(decoded.regularPrice == "24.99")
        #expect(decoded.salePrice == "19.99")
        #expect(decoded.stockStatus == "instock")
        #expect(decoded.stockQuantity == 5)
    }

    @Test
    func test_decode_ProductVariationCardPayload_from_snake_case_json_then_populates_fields() throws {
        // Given
        let data = Data("""
        {"id": 99, "parent_id": 42, "name": "Black", "sku": "BEAN-BLK",
         "price": "19.99", "stock_status": "instock"}
        """.utf8)

        // When
        let decoded = try JSONDecoder().decode(ProductVariationCardPayload.self, from: data)

        // Then
        #expect(decoded.id == 99)
        #expect(decoded.parentID == 42)
        #expect(decoded.stockStatus == "instock")
    }

    @Test
    func test_decode_CustomerCardPayload_from_snake_case_json_then_populates_fields() throws {
        // Given
        let data = Data("""
        {"id": 7, "first_name": "Jane", "last_name": "Doe",
         "email": "jane@example.com", "username": "jdoe", "orders_count": 12}
        """.utf8)

        // When
        let decoded = try JSONDecoder().decode(CustomerCardPayload.self, from: data)

        // Then
        #expect(decoded.id == 7)
        #expect(decoded.firstName == "Jane")
        #expect(decoded.lastName == "Doe")
        #expect(decoded.ordersCount == 12)
    }
}
