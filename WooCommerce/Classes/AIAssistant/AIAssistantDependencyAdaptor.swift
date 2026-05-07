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
    let jwtProvider: AssistantJWTProviding

    let chatService: AIChatService
    let toolRegistry: ToolRegistry
    let safetyPolicy: SafetyPolicy
    let systemPromptProvider: @Sendable () -> String?
    let maxIterations: Int
    let context: AssistantContext

    @MainActor
    static func `default`(siteID: Int64,
                          site: Yosemite.Site,
                          navigationHost: AIAssistantNavigationHost,
                          stores: StoresManager = ServiceLocator.stores,
                          analytics: Analytics = ServiceLocator.analytics,
                          appPasswordSupport: AnyPublisher<Bool, Never> = Just(false).eraseToAnyPublisher())
                          -> AIAssistantDependencyAdaptor {
        let credentials = stores.sessionManager.defaultCredentials
        let defaultSitePublisher = stores.sessionManager.defaultSitePublisher
            .map { $0?.toJetpackSite() }
            .eraseToAnyPublisher()

        // LLM endpoint goes plain WPCOM, WC REST goes through the Jetpack tunnel.
        let wpcomNetwork = AlamofireNetwork(credentials: credentials,
                                            selectedSite: nil,
                                            appPasswordSupportState: nil)
        let restNetwork = AlamofireNetwork(credentials: credentials,
                                           selectedSite: defaultSitePublisher,
                                           appPasswordSupportState: appPasswordSupport)

        let jwtAdaptor = AIAssistantJWTAdaptor(blogID: siteID, network: wpcomNetwork)
        let chatService = makeJetpackAIChatService(jwtProvider: jwtAdaptor)

        let restClient = WCRESTClientAdaptor(network: restNetwork, siteID: siteID)
        let toolRegistry = RESTToolRegistry(
            client: restClient,
            tools: Self.defaultTools(siteID: siteID,
                                     stores: stores,
                                     restClient: restClient)
        )
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
            jwtProvider: jwtAdaptor,
            chatService: chatService,
            toolRegistry: toolRegistry,
            safetyPolicy: DefaultSafetyPolicy(snapshotResolver: snapshotResolver),
            systemPromptProvider: { AssistantSystemPrompt.build() },
            maxIterations: AgenticLoopOrchestrator.defaultMaxIterations,
            context: context
        )
    }

    @MainActor
    private static func defaultTools(siteID: Int64,
                                     stores: StoresManager,
                                     restClient: WCRESTClient) -> [RESTTool] {
        let dispatch: @MainActor @Sendable (Action) -> Void = { action in stores.dispatch(action) }
        let storageManager = ServiceLocator.storageManager
        return [
            OrdersListTool.make(),
            OrdersGetTool.make(),
            OrdersUpdateTool.make(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            OrdersBulkUpdateTool.make(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            ProductsListTool.make(),
            ProductsGetTool.make(),
            ProductsUpdateTool.make(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            ProductsBulkUpdateTool.make(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            ProductVariationsListTool.make(),
            ProductVariationsUpdateTool.make(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            ProductVariationsBulkUpdateTool.make(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            CustomersListTool.make(),
            AnalyticsOrdersTool.make(),
            AnalyticsRevenueTool.make(),
            ShowCardsTool.make(siteID: siteID,
                               storageManager: storageManager,
                               dispatchAction: dispatch,
                               restClient: restClient)
        ]
    }
}
