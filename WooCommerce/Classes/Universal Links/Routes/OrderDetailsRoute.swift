import Foundation
import Yosemite

/// Shows order details from a given universal link that matches the right path
///
struct OrderDetailsRoute: Route {
    let path = "/orders/details"

    private let switchStoreUseCase: SwitchStoreUseCaseProtocol

    init(switchStoreUseCase: SwitchStoreUseCaseProtocol = SwitchStoreUseCase(stores: ServiceLocator.stores)) {
        self.switchStoreUseCase = switchStoreUseCase
    }

    func perform(with parameters: [String: String]) {
        guard let storeIdString = parameters[ParametersKeys.blogId],
              let storeId = Int64(storeIdString),
              let orderId = parameters[ParametersKeys.orderId] else {
            return
        }

        switchStoreUseCase.switchStore(with: storeId, onCompletion: { siteChanged in
            if siteChanged {
                let presenter = SwitchStoreNoticePresenter(siteID: storeId)
                presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)
                MainTabBarController.switchToOrdersTab()
            }
        })
    }
}

private extension OrderDetailsRoute {
    enum ParametersKeys {
        static let blogId = "blog_id"
        static let orderId = "order_id"
    }
}
