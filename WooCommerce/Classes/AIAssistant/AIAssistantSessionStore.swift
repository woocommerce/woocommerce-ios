import Foundation
import WooAIAssistant

/// Survives `.fullScreenCover` dismissal so the chat resumes the prior conversation.
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
    private var logoutObserver: NSObjectProtocol?

    private init() {
        logoutObserver = NotificationCenter.default.addObserver(forName: .logOutEventReceived,
                                                                object: nil,
                                                                queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.invalidateAll()
            }
        }
    }

    nonisolated deinit {
        if let logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }
    }

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

    func invalidateAll() {
        entries.removeAll()
        pendingHosts.removeAll()
    }

    func hasSession(for siteID: Int64) -> Bool {
        entries[siteID] != nil
    }
}

#if DEBUG
extension AIAssistantSessionStore {
    static func makeForTesting() -> AIAssistantSessionStore {
        AIAssistantSessionStore()
    }
}
#endif
