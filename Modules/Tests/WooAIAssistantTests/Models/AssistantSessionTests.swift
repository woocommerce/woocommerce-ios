import Testing
@testable import WooAIAssistant

struct AssistantSessionTests {
    @Test
    func test_assistantSession_when_constructed_with_session_id_only_then_task_id_is_nil() {
        // Given / When
        let session = AssistantSession(sessionID: "sess_abc")

        // Then
        #expect(session.sessionID == "sess_abc")
        #expect(session.taskID == nil)
    }

    @Test
    func test_assistantSession_when_constructed_with_task_id_then_both_exposed() {
        // Given / When
        let session = AssistantSession(sessionID: "sess_abc", taskID: "task_xyz")

        // Then
        #expect(session.sessionID == "sess_abc")
        #expect(session.taskID == "task_xyz")
    }
}
