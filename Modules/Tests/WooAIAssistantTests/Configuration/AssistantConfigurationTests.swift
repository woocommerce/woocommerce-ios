import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantConfigurationTests {
    @Test
    func test_pinned_constants_match_documented_values() {
        #expect(AssistantConfiguration.chatModel == "gpt-4o")
        #expect(AssistantConfiguration.featureName == "woo-ai-assistant")
    }
}
