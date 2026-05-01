import Testing
import Yosemite
import WooAIAssistant
@testable import WooCommerce

@MainActor
struct AIAssistantDependencyAdaptorTests {

    @Test
    func test_default_when_called_then_returns_dependencies_with_jwt_provider_bound_to_site() {
        // Given
        let site = Site.fake().copy(siteID: 123, url: "https://store.test", isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()

        // When
        let result = AIAssistantDependencyAdaptor.default(siteID: 123,
                                                           site: site,
                                                           navigationHost: host,
                                                           stores: stores)

        // Then
        #expect(result.context.siteID == 123)
        #expect(result.context.blogID == 123)
        #expect(result.context.siteURL.absoluteString == "https://store.test")
    }

    @Test
    func test_default_when_called_then_safety_policy_is_default_not_alwaysExecute() {
        // Given
        let site = Site.fake().copy(siteID: 1, url: "https://store.test")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()

        // When
        let result = AIAssistantDependencyAdaptor.default(siteID: 1,
                                                           site: site,
                                                           navigationHost: host,
                                                           stores: stores)

        // Then
        #expect(result.safetyPolicy is DefaultSafetyPolicy)
    }

    @Test
    func test_default_when_called_then_max_iterations_matches_orchestrator_default() {
        // Given
        let site = Site.fake().copy(siteID: 1, url: "https://store.test")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()

        // When
        let result = AIAssistantDependencyAdaptor.default(siteID: 1,
                                                           site: site,
                                                           navigationHost: host,
                                                           stores: stores)

        // Then
        #expect(result.maxIterations == AgenticLoopOrchestrator.defaultMaxIterations)
    }

    @Test
    func test_default_when_called_then_system_prompt_provider_returns_non_nil() {
        // Given
        let site = Site.fake().copy(siteID: 1, url: "https://store.test")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()

        // When
        let result = AIAssistantDependencyAdaptor.default(siteID: 1,
                                                           site: site,
                                                           navigationHost: host,
                                                           stores: stores)
        let prompt = result.systemPromptProvider()

        // Then
        #expect(prompt != nil)
        #expect(prompt?.isEmpty == false)
    }
}
