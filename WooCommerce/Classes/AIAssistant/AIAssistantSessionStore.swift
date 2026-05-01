import Foundation
import WooAIAssistant

/// Process-local cache so the chat survives drill-downs into detail VCs and re-presentations
/// without losing the conversation. SwiftUI `@State` dies on dismissal of `.fullScreenCover`,
/// so the controller has to live somewhere outside the view tree. The nav host is cached too
/// because the external-nav adaptor holds a strong reference to it; rebuilding the host every
/// presentation would leave the cached adaptor pointing at a dead nav controller.
@MainActor
final class AIAssistantSessionStore {

    static let shared = AIAssistantSessionStore()

    private struct Entry {
        let controller: AssistantController
        let dependencies: AIAssistantDependencyAdaptor
        let navigationHost: AIAssistantNavigationHost
    }

    private var entries: [Int64: Entry] = [:]
    private var pendingHosts: [Int64: AIAssistantNavigationHost] = [:]

    init() {}

    func navigationHost(for siteID: Int64) -> AIAssistantNavigationHost {
        if let cached = entries[siteID] {
            return cached.navigationHost
        }
        if let pending = pendingHosts[siteID] {
            return pending
        }
        let host = AIAssistantNavigationHost()
        pendingHosts[siteID] = host
        return host
    }

    func controller(for siteID: Int64,
                    makeDependencies: (AIAssistantNavigationHost) -> AIAssistantDependencyAdaptor) -> AssistantController {
        if let cached = entries[siteID] {
            return cached.controller
        }
        let host = pendingHosts[siteID] ?? AIAssistantNavigationHost()
        pendingHosts[siteID] = nil
        let dependencies = makeDependencies(host)
        let backend = AgenticChatBackend(chatService: dependencies.chatService,
                                         toolRegistry: dependencies.toolRegistry,
                                         safetyPolicy: dependencies.safetyPolicy,
                                         systemPromptProvider: dependencies.systemPromptProvider,
                                         maxIterations: dependencies.maxIterations)
        let controller = AssistantController(backend: backend, context: dependencies.context)
        entries[siteID] = Entry(controller: controller,
                                dependencies: dependencies,
                                navigationHost: host)
        return controller
    }

    func dependencies(for siteID: Int64) -> AIAssistantDependencyAdaptor? {
        entries[siteID]?.dependencies
    }

    func resetSession(for siteID: Int64) {
        entries[siteID] = nil
        pendingHosts[siteID] = nil
    }

    func hasSession(for siteID: Int64) -> Bool {
        entries[siteID] != nil
    }
}
