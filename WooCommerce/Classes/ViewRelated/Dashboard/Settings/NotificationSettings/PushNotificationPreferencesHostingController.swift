import SwiftUI
import Yosemite

final class PushNotificationPreferencesHostingController: UIHostingController<PushNotificationPreferencesView> {
    private let viewModel: PushNotificationPreferencesViewModel

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        let viewModel = PushNotificationPreferencesViewModel(siteID: siteID, stores: stores)
        self.viewModel = viewModel
        super.init(rootView: PushNotificationPreferencesView(viewModel: viewModel))
        // Set after `super.init` so the closures can capture `self` weakly.
        rootView.onNewOrderTapped = { [weak self] in
            self?.showNewOrderDetail()
        }
        rootView.onNewReviewTapped = { [weak self] in
            self?.showNewReviewDetail()
        }
        rootView.onNewStockTapped = { [weak self] in
            self?.showNewStockDetail()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showNewOrderDetail() {
        let detail = NewOrderNotificationPreferencesHostingController(viewModel: viewModel)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func showNewReviewDetail() {
        let detail = NewReviewNotificationPreferencesHostingController(viewModel: viewModel)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func showNewStockDetail() {
        let detail = NewStockNotificationPreferencesHostingController(viewModel: viewModel)
        navigationController?.pushViewController(detail, animated: true)
    }
}
