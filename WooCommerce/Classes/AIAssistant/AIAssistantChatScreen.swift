import SwiftUI
import Combine
import Yosemite
import WooAIAssistant

struct AIAssistantChatScreen: View {

    let site: Site
    let onClose: () -> Void

    @State private var controller: AssistantController?
    @State private var navigationHost: AIAssistantNavigationHost?
    @State private var appPasswordSupportState = ApplicationPasswordsExperimentState()

    var body: some View {
        Group {
            if let navigationHost, let controller {
                AIAssistantChatNavHost(host: navigationHost) {
                    AssistantChatView(controller: controller, onClose: onClose)
                }
                .ignoresSafeArea()
            } else {
                Color.assistantSurface.ignoresSafeArea()
            }
        }
        .onAppear {
            buildControllerIfNeeded()
        }
    }

    private func buildControllerIfNeeded() {
        guard controller == nil else { return }
        let store = AIAssistantSessionStore.shared
        let host = store.navigationHost(for: site.siteID)
        let appPasswordSupport = appPasswordSupportState
            .$isAvailableAndEnabled
            .eraseToAnyPublisher()
        let controllerInstance = store.controller(for: site.siteID) { resolvedHost in
            AIAssistantDependencyAdaptor.default(siteID: site.siteID,
                                                  site: site,
                                                  navigationHost: resolvedHost,
                                                  appPasswordSupport: appPasswordSupport)
        }
        navigationHost = host
        controller = controllerInstance
    }
}
