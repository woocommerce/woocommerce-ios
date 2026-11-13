import Combine
import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import struct NetworkingCore.JetpackSite
import protocol WooFoundation.Analytics

/// The services the order details refund flow needs to preview and create server-calculated refunds.
struct ServerRefundDependencies {
    let previewUseCase: ServerRefundPreviewUseCase
    let refundService: RefundServiceProtocol

    /// Kept alive for the network's lifetime: the network observes its published support state.
    private let appPasswordSupportState: ApplicationPasswordsExperimentState?

    init(previewUseCase: ServerRefundPreviewUseCase,
         refundService: RefundServiceProtocol,
         appPasswordSupportState: ApplicationPasswordsExperimentState? = nil) {
        self.previewUseCase = previewUseCase
        self.refundService = refundService
        self.appPasswordSupportState = appPasswordSupportState
    }

    /// Builds the services for the current session the same way the POS tab does.
    /// Returns nil without credentials; the flow then keeps the local calculation.
    @MainActor
    static func make(stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     analytics: Analytics = ServiceLocator.analytics) -> ServerRefundDependencies? {
        let sessionManager = stores.sessionManager
        let appPasswordSupportState = ApplicationPasswordsExperimentState(stores: stores)
        guard let refundService = RefundService(credentials: sessionManager.defaultCredentials,
                                                selectedSite: sessionManager.defaultSitePublisher
                                                    .map { $0?.toJetpackSite() }
                                                    .eraseToAnyPublisher(),
                                                appPasswordSupportState: appPasswordSupportState
                                                    .$isAvailableAndEnabled
                                                    .eraseToAnyPublisher(),
                                                storageManager: storageManager) else {
            return nil
        }
        let flowResolver = RefundFlowResolver(stores: stores,
                                              availabilityCache: .shared,
                                              minimumWooVersion: RefundFlowResolver.Constants.minimumWooVersionForServerRefunds)
        // No unavailable event here: `refund_flow` on the refund create events already reports which path ran.
        let previewUseCase = ServerRefundPreviewUseCase(refundService: refundService,
                                                        flowResolver: flowResolver,
                                                        availabilityCache: .shared,
                                                        analytics: analytics,
                                                        serverFlowUnavailableEvent: nil)
        return ServerRefundDependencies(previewUseCase: previewUseCase,
                                        refundService: refundService,
                                        appPasswordSupportState: appPasswordSupportState)
    }
}
