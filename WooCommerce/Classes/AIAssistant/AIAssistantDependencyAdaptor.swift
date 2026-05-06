import Foundation
import Combine
import Storage
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
                          storageManager: StorageManagerType = ServiceLocator.storageManager,
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
                                     storageManager: storageManager,
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

    private static func defaultTools(siteID: Int64,
                                     storageManager: StorageManagerType,
                                     stores: StoresManager,
                                     restClient: WCRESTClient) -> [RESTTool] {
        let dispatch: @Sendable (Action) -> Void = { action in stores.dispatch(action) }
        let providers: [CardFamily: any CardEntityProvider] = [
            .order: OrderCardProvider(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            .product: ProductCardProvider(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            .productVariation: VariationCardProvider(siteID: siteID, storageManager: storageManager, dispatchAction: dispatch),
            .customer: CustomerCardProvider(client: restClient)
        ]
        return [
            OrdersListTool.make(),
            OrdersGetTool.make(),
            OrdersUpdateTool.make(),
            OrdersBulkUpdateTool.make(),
            ProductsListTool.make(),
            ProductsGetTool.make(),
            ProductsUpdateTool.make(),
            ProductsBulkUpdateTool.make(),
            ProductVariationsListTool.make(),
            ProductVariationsUpdateTool.make(),
            ProductVariationsBulkUpdateTool.make(),
            CustomersListTool.make(),
            AnalyticsOrdersTool.make(),
            AnalyticsRevenueTool.make(),
            ShowCardsTool.make(providers: providers)
        ]
    }
}
