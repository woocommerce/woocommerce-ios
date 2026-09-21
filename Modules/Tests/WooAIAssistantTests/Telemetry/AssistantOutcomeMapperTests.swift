import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantOutcomeMapperTests {

    @Test
    func test_map_when_completed_then_returns_success() {
        #expect(AssistantOutcomeMapper.map(.completed) == .success)
    }

    @Test
    func test_map_when_failed_then_returns_failed() {
        let error = AssistantError(kind: .network, message: "boom")
        #expect(AssistantOutcomeMapper.map(.failed(error)) == .failed)
    }

    @Test
    func test_map_when_stopped_then_returns_cancelledByUser() {
        #expect(AssistantOutcomeMapper.map(.stopped) == .cancelledByUser)
    }

    @Test
    func test_map_when_maxIterations_then_returns_maxIterations() {
        #expect(AssistantOutcomeMapper.map(.maxIterations(iterations: 5)) == .maxIterations)
    }
}
