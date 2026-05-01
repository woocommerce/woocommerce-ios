import Testing
import UIKit
import WooAIAssistant
@testable import WooCommerce

@MainActor
struct AIAssistantSessionStoreTests {

    @Test
    func test_controller_when_called_twice_for_same_site_then_returns_same_instance() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()
        var buildCount = 0
        let make: (AIAssistantNavigationHost) -> AIAssistantDependencyAdaptor = { _ in
            buildCount += 1
            return makeStubDependencies()
        }

        // When
        let first = sut.controller(for: 99, makeDependencies: make)
        let second = sut.controller(for: 99, makeDependencies: make)

        // Then
        #expect(first === second)
        #expect(buildCount == 1)
    }

    @Test
    func test_controller_when_called_for_different_sites_then_returns_distinct_instances() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()

        // When
        let firstSite = sut.controller(for: 11) { _ in makeStubDependencies() }
        let secondSite = sut.controller(for: 22) { _ in makeStubDependencies() }

        // Then
        #expect(firstSite !== secondSite)
    }

    @Test
    func test_resetSession_when_called_then_subsequent_controller_is_new_instance() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()
        let first = sut.controller(for: 12) { _ in makeStubDependencies() }

        // When
        sut.resetSession(for: 12)
        let second = sut.controller(for: 12) { _ in makeStubDependencies() }

        // Then
        #expect(first !== second)
    }

    @Test
    func test_resetSession_when_called_then_pendingHost_for_that_site_is_cleared() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()
        let firstHost = sut.navigationHost(for: 33)

        // When
        sut.resetSession(for: 33)
        let secondHost = sut.navigationHost(for: 33)

        // Then
        #expect(firstHost !== secondHost)
    }

    @Test
    func test_navigationHost_when_called_twice_for_same_site_then_returns_same_instance() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()

        // When
        let first = sut.navigationHost(for: 5)
        let second = sut.navigationHost(for: 5)

        // Then
        #expect(first === second)
    }

    @Test
    func test_navigationHost_when_set_then_controller_for_same_site_uses_that_host() {
        // Given
        let sut = AIAssistantSessionStore.makeForTesting()
        let host = sut.navigationHost(for: 8)
        let nav = UINavigationController()
        host.attach(nav)

        // When
        var capturedHost: AIAssistantNavigationHost?
        _ = sut.controller(for: 8) { resolvedHost in
            capturedHost = resolvedHost
            return makeStubDependencies()
        }

        // Then
        #expect(capturedHost === host)
        #expect(capturedHost?.navigationController === nav)
    }
}

@MainActor
private func makeStubDependencies() -> AIAssistantDependencyAdaptor {
    AIAssistantDependencyAdaptor(
        analytics: StubAnalytics(),
        externalNavigation: StubNavigation(),
        externalViews: AIAssistantExternalViewsAdaptor(),
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

private struct StubNavigation: AssistantExternalNavigationProviding {
    func openOrder(siteID: Int64, orderID: Int64) {}
    func openProduct(siteID: Int64, productID: Int64) {}
    func openCustomer(siteID: Int64, customerID: Int64) {}
}

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
