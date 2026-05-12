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

    struct Session {
        let controller: AssistantController
        let navigationHost: AIAssistantNavigationHost
        let externalNavigation: AssistantExternalNavigationProviding
        let externalViews: AssistantExternalViewProviding
    }

    func session(for siteID: Int64,
                 makeDependencies: (AIAssistantNavigationHost) -> AIAssistantDependencyAdaptor) -> Session {
        if let cached = entries[siteID] {
            return Session(controller: cached.controller,
                           navigationHost: cached.navigationHost,
                           externalNavigation: cached.dependencies.externalNavigation,
                           externalViews: cached.dependencies.externalViews)
        }
        let host = AIAssistantNavigationHost()
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
        return Session(controller: controller,
                       navigationHost: host,
                       externalNavigation: dependencies.externalNavigation,
                       externalViews: dependencies.externalViews)
    }

    func dependencies(for siteID: Int64) -> AIAssistantDependencyAdaptor? {
        entries[siteID]?.dependencies
    }

    func resetSession(for siteID: Int64) {
        entries[siteID] = nil
    }

    func invalidateAll() {
        entries.removeAll()
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
