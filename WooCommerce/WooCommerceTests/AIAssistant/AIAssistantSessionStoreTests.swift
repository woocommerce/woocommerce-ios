import Testing
import UIKit
import WooAIAssistant
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AIAssistantSessionStoreTests {

    @Test
    func test_session_when_called_twice_for_same_site_then_returns_same_controller() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()
        var buildCount = 0
        let make: (AIAssistantNavigationHost) -> AIAssistantDependencyAdaptor = { _ in
            buildCount += 1
            return makeStubDependencies()
        }

        // When
        let first = sut.session(for: 99, makeDependencies: make)
        let second = sut.session(for: 99, makeDependencies: make)

        // Then
        #expect(first.controller === second.controller)
        #expect(buildCount == 1)
    }

    @Test
    func test_session_when_called_for_different_sites_then_returns_distinct_controllers() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()

        // When
        let firstSite = sut.session(for: 11) { _ in makeStubDependencies() }
        let secondSite = sut.session(for: 22) { _ in makeStubDependencies() }

        // Then
        #expect(firstSite.controller !== secondSite.controller)
    }

    @Test
    func test_resetSession_when_called_then_subsequent_session_is_new_instance() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()
        let first = sut.session(for: 12) { _ in makeStubDependencies() }

        // When
        sut.resetSession(for: 12)
        let second = sut.session(for: 12) { _ in makeStubDependencies() }

        // Then
        #expect(first.controller !== second.controller)
    }

    @Test
    func test_session_when_called_twice_for_same_site_then_returns_same_navigation_host() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()

        // When
        let first = sut.session(for: 5) { _ in makeStubDependencies() }
        let second = sut.session(for: 5) { _ in makeStubDependencies() }

        // Then
        #expect(first.navigationHost === second.navigationHost)
    }

    @Test
    func test_session_when_makeDependencies_called_then_resolved_host_matches_returned_session() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()

        // When
        var capturedHost: AIAssistantNavigationHost?
        let session = sut.session(for: 8) { resolvedHost in
            capturedHost = resolvedHost
            return makeStubDependencies()
        }

        // Then
        #expect(capturedHost === session.navigationHost)
    }
}

@MainActor
private func makeStubDependencies() -> AIAssistantDependencyAdaptor {
    AIAssistantDependencyAdaptor(
        analytics: StubAnalytics(),
        externalNavigation: StubNavigation(),
        externalViews: StubExternalViews(),
        jwtProvider: StubJWT(),
        chatService: StubChatService(),
        toolRegistry: StubToolRegistry(),
        safetyPolicy: DefaultSafetyPolicy(),
        systemPromptProvider: { nil },
        maxIterations: 3,
        context: AssistantContext(siteID: 1,
                                   siteURL: URL(string: "https://store.test")!,
                                   blogID: 1)
    )
}

private struct StubAnalytics: AssistantAnalyticsProviding {
    func track(event: String, properties: [String: String]) {}
}

@MainActor
private struct StubNavigation: AssistantExternalNavigationProviding {
    func openOrder(orderID: Int64) {}
    func openProduct(productID: Int64) {}
    func openProductVariation(productID: Int64, variationID: Int64) {}
    func openCustomer(customerID: Int64) {}
}

private struct StubExternalViews: AssistantExternalViewProviding {}

private struct StubJWT: AssistantJWTProviding {
    func currentJWT() async throws -> String { "stub" }
}

private struct StubChatService: AIChatService {
    func streamTurn(messages: [OpenAIChat.Message],
                    tools: [OpenAIChat.ToolDefinition]?,
                    toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

private struct StubToolRegistry: ToolRegistry {
    func availableTools() async throws -> [AITool] { [] }
    func execute(name: String, arguments: String, toolCallID: String) async -> ToolResult {
        .failed(.init(toolName: name, toolCallID: toolCallID, kind: .invalidToolCall, reason: "stub"))
    }
}
