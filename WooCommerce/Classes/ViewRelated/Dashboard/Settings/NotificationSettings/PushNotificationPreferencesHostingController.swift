import SwiftUI
import Yosemite

final class PushNotificationPreferencesHostingController: UIHostingController<PushNotificationPreferencesView> {
    private let viewModel: PushNotificationPreferencesViewModel

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        let viewModel = PushNotificationPreferencesViewModel(siteID: siteID, stores: stores)
        self.viewModel = viewModel
        super.init(rootView: PushNotificationPreferencesView(viewModel: viewModel))
        // Set after `super.init` so the closure can capture `self` weakly.
        rootView.onNewOrderTapped = { [weak self] in
            self?.showNewOrderDetail()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showNewOrderDetail() {
        let detail = NewOrderNotificationPreferencesHostingController(viewModel: viewModel)
        navigationController?.pushViewController(detail, animated: true)
    }
}
