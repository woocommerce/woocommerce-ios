import Foundation
import WooAIAssistant

/// Process-local cache so the chat survives drill-downs into detail VCs and re-presentations
/// without losing the conversation. SwiftUI `@State` dies on dismissal of `.fullScreenCover`,
/// so the controller has to live somewhere outside the view tree.
@MainActor
final class AIAssistantSessionStore {

    static let shared = AIAssistantSessionStore()

    private struct Entry {
        let controller: AssistantController
        let dependencies: AIAssistantDependencyAdaptor
    }

    private var entries: [Int64: Entry] = [:]

    init() {}

    func controller(for siteID: Int64,
                    makeDependencies: () -> AIAssistantDependencyAdaptor) -> AssistantController {
        if let cached = entries[siteID] {
            return cached.controller
        }
        let dependencies = makeDependencies()
        let backend = AgenticChatBackend(chatService: dependencies.chatService,
                                         toolRegistry: dependencies.toolRegistry,
                                         safetyPolicy: dependencies.safetyPolicy,
                                         systemPromptProvider: dependencies.systemPromptProvider,
                                         maxIterations: dependencies.maxIterations)
        let controller = AssistantController(backend: backend, context: dependencies.context)
        entries[siteID] = Entry(controller: controller, dependencies: dependencies)
        return controller
    }

    func dependencies(for siteID: Int64) -> AIAssistantDependencyAdaptor? {
        entries[siteID]?.dependencies
    }

    func resetSession(for siteID: Int64) {
        entries[siteID] = nil
    }

    func hasSession(for siteID: Int64) -> Bool {
        entries[siteID] != nil
    }
}
