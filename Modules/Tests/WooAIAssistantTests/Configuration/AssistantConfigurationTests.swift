import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantConfigurationTests {
    @Test
    func test_pinned_constants_match_documented_values() {
        #expect(AssistantConfiguration.chatModel == "gpt-5.1")
        #expect(AssistantConfiguration.featureName == "woo-ai-assistant")
    }
}
