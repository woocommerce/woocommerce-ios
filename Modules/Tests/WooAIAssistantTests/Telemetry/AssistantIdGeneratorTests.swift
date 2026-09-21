import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantIdGeneratorTests {

    @Test
    func test_nextID_when_called_then_returns_uuid_formatted_string() {
        // Given
        let generator = UUIDAssistantIdGenerator()

        // When
        let id = generator.nextID()

        // Then
        #expect(UUID(uuidString: id) != nil)
    }

    @Test
    func test_nextID_when_called_repeatedly_then_returns_unique_values() {
        // Given
        let generator = UUIDAssistantIdGenerator()

        // When
        let ids = (0..<32).map { _ in generator.nextID() }

        // Then
        #expect(Set(ids).count == ids.count)
    }
}
