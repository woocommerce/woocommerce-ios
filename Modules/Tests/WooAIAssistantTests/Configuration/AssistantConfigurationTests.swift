import Testing
@testable import WooAIAssistant

struct AssistantConfigurationTests {
    @Test
    func test_assistantConfiguration_when_inspected_then_pins_release_triple() {
        #expect(AssistantConfiguration.chatModel == "gpt-4o-mini")
        #expect(AssistantConfiguration.promptVersion == "v1")
        #expect(AssistantConfiguration.toolCatalogVersion == "v1")
    }
}
