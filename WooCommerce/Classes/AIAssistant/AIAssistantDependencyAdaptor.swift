import Foundation
import Combine
import Yosemite
import struct NetworkingCore.JetpackSite
import enum NetworkingCore.Credentials
import class NetworkingCore.AlamofireNetwork
import WooAIAssistant
import protocol WooFoundation.Analytics

struct AIAssistantDependencyAdaptor: AssistantDependencyProviding {

    let analytics: AssistantAnalyticsProviding
    let externalNavigation: AssistantExternalNavigationProviding
    let externalViews: AssistantExternalViewProviding

    let chatService: AIChatService
    let toolRegistry: ToolRegistry
    let safetyPolicy: SafetyPolicy
    let systemPromptProvider: @Sendable () -> String?
    let maxIterations: Int
    let context: AssistantContext

    @MainActor
    static func `default`(siteID: Int64,
                          site: Site,
                          navigationHost: AIAssistantNavigationHost,
                          stores: StoresManager = ServiceLocator.stores,
                          analytics: Analytics = ServiceLocator.analytics,
                          appPasswordSupport: AnyPublisher<Bool, Never> = Just(false).eraseToAnyPublisher())
                          -> AIAssistantDependencyAdaptor {
        let credentials = stores.sessionManager.defaultCredentials
        let defaultSitePublisher = stores.sessionManager.defaultSitePublisher
            .map { $0?.toJetpackSite() }
            .eraseToAnyPublisher()

        let restNetwork = AlamofireNetwork(credentials: credentials,
                                           selectedSite: defaultSitePublisher,
                                           appPasswordSupportState: appPasswordSupport)

        let chatService = AIApiProxyChatService(tokenProvider: AIApiProxyTokenAdaptor(credentials: credentials))

        let restClient = WCRESTClientAdaptor(network: restNetwork, siteID: siteID)
        let toolRegistry = RESTToolRegistry(client: restClient, tools: Self.defaultTools())
        let snapshotResolver = DefaultConfirmationSnapshotResolver(client: restClient)

        let siteURL = URL(string: site.url) ?? URL(fileURLWithPath: "/")
        let context = AssistantContext(siteID: siteID,
                                        siteURL: siteURL,
                                        blogID: siteID)

        return AIAssistantDependencyAdaptor(
            analytics: AIAssistantAnalyticsAdaptor(analytics: analytics),
            externalNavigation: AIAssistantExternalNavigationAdaptor(siteID: siteID,
                                                                       navigationHost: navigationHost,
                                                                       stores: stores),
            externalViews: AIAssistantExternalViewsAdaptor(),
            chatService: chatService,
            toolRegistry: toolRegistry,
            safetyPolicy: DefaultSafetyPolicy(snapshotResolver: snapshotResolver),
            systemPromptProvider: { AssistantSystemPrompt.build() },
            maxIterations: AgenticLoopOrchestrator.defaultMaxIterations,
            context: context
        )
    }

    private static func defaultTools() -> [RESTTool] {
        [
            OrdersListTool.make(),
            OrdersGetTool.make(),
            OrdersUpdateTool.make(),
            OrdersBulkUpdateTool.make(),
            ProductsListTool.make(),
            ProductsUpdateTool.make(),
            CustomersListTool.make(),
            AnalyticsOrdersTool.make(),
            ShowCardsTool.make()
        ]
    }
}
