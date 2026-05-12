import SwiftUI
import Combine
import Yosemite
import WooAIAssistant

struct AIAssistantChatScreen: View {

    let site: Site
    let onClose: () -> Void

    @State private var controller: AssistantController?
    @State private var navigationHost: AIAssistantNavigationHost?
    @State private var externalNavigation: AssistantExternalNavigationProviding?
    @State private var externalViews: AssistantExternalViewProviding?
    @State private var appPasswordSupportState = ApplicationPasswordsExperimentState()

    var body: some View {
        Group {
            if let navigationHost, let controller, let externalNavigation, let externalViews {
                AIAssistantChatNavHost(host: navigationHost) {
                    AssistantChatView(controller: controller, onClose: onClose)
                        .environment(\.assistantExternalNavigation, externalNavigation)
                        .environment(\.assistantExternalViews, externalViews)
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
        let appPasswordSupport = appPasswordSupportState
            .$isAvailableAndEnabled
            .eraseToAnyPublisher()
        let session = store.session(for: site.siteID) { resolvedHost in
            AIAssistantDependencyAdaptor.default(siteID: site.siteID,
                                                  site: site,
                                                  navigationHost: resolvedHost,
                                                  appPasswordSupport: appPasswordSupport)
        }
        navigationHost = session.navigationHost
        controller = session.controller
        externalNavigation = session.externalNavigation
        externalViews = session.externalViews
    }
}
