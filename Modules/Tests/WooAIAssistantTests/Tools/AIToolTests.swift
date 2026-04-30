import Foundation
import Testing
@testable import WooAIAssistant

struct AIToolTests {
    @Test
    func test_aiTool_when_constructed_then_exposes_name_description_schema_and_safetyLevel() {
        // Given
        let schema: AnyCodableJSON = .object([
            "type": .string("object"),
            "properties": .object([
                "site_id": .object(["type": .string("integer")]),
                "order_id": .object(["type": .string("integer")])
            ]),
            "required": .array([.string("site_id"), .string("order_id")])
        ])

        // When
        let tool = AITool(name: "orders_get",
                          description: "Fetch a single order by ID",
                          parametersSchema: schema,
                          safetyLevel: .safe)

        // Then
        #expect(tool.name == "orders_get")
        #expect(tool.description == "Fetch a single order by ID")
        #expect(tool.parametersSchema == schema)
        #expect(tool.safetyLevel == .safe)
    }

    @Test
    func test_aiTool_when_parametersSchema_round_trips_through_json_then_preserves_shape() throws {
        // Given
        let schema: AnyCodableJSON = .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object(["type": .string("string")])
            ])
        ])
        let tool = AITool(name: "products_search",
                          description: "Search products",
                          parametersSchema: schema,
                          safetyLevel: .safe)

        // When
        let data = try JSONEncoder().encode(tool.parametersSchema)
        let decoded = try JSONDecoder().decode(AnyCodableJSON.self, from: data)

        // Then
        #expect(decoded == schema)
    }
}
