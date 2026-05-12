import SwiftUI
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct EntityCardTests {

    @Test
    func test_visibleRows_when_payloads_are_all_empty_then_returns_empty() {
        // Given
        let payloads = [OrderCardPayload(), OrderCardPayload()]

        // When
        let result = EntityCard<OrderCardPayload, AnyView>.visibleRows(payloads, isEmpty: { $0.isEmpty })

        // Then
        #expect(result.isEmpty)
    }

    @Test
    func test_visibleRows_when_payloads_have_data_then_returns_non_empty_payloads() {
        // Given
        let payloads = [
            OrderCardPayload(id: 1),
            OrderCardPayload(),
            OrderCardPayload(id: 2)
        ]

        // When
        let result = EntityCard<OrderCardPayload, AnyView>.visibleRows(payloads, isEmpty: { $0.isEmpty })

        // Then
        #expect(result.count == 2)
        #expect(result[0].id == 1)
        #expect(result[1].id == 2)
    }

    @Test
    func test_visibleRows_when_payloads_exceed_limit_then_caps_to_visible_limit() {
        // Given
        let payloads = (1...20).map { OrderCardPayload(id: Int64($0)) }

        // When
        let result = EntityCard<OrderCardPayload, AnyView>.visibleRows(payloads, isEmpty: { $0.isEmpty })

        // Then
        #expect(result.count == entityCardVisibleRowLimit)
    }

    @Test
    func test_visibleRowLimit_is_ten() {
        #expect(entityCardVisibleRowLimit == 10)
    }

}
