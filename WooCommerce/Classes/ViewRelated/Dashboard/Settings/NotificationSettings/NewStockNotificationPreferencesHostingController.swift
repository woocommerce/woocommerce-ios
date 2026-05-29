import SwiftUI
import Yosemite

/// Hosts `NewStockNotificationPreferencesDetailView`. Navigation chrome
/// (Save, back button, discard alert, saving spinner) is inherited from
/// `NotificationDetailHostingController`.
///
final class NewStockNotificationPreferencesHostingController:
    NotificationDetailHostingController<NewStockNotificationPreferencesDetailView> {

    private let detailViewModel: NewStockNotificationPreferencesDetailViewModel

    init(viewModel: PushNotificationPreferencesViewModel,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        let detailViewModel = NewStockNotificationPreferencesDetailViewModel(
            siteID: siteID,
            siteAdminURL: stores.sessionManager.defaultSite?.adminURLWithFallback(),
            stores: stores)
        self.detailViewModel = detailViewModel
        super.init(viewModel: viewModel,
                   rootView: NewStockNotificationPreferencesDetailView(
                       viewModel: viewModel,
                       detailViewModel: detailViewModel),
                   notificationType: .stockAlert,
                   onDiscard: { [weak viewModel] in viewModel?.discardStoreStockEdits() })
        detailViewModel.onTapEditStoreWideThreshold = { [weak self] in
            self?.presentEditStoreWideThreshold()
        }
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func presentEditStoreWideThreshold() {
        guard let url = detailViewModel.editStoreWideThresholdURL else { return }
        let webModel = EditLowStockThresholdWebViewModel(
            title: Localization.editThresholdWebTitle,
            initialURL: url,
            onDisappear: { [weak detailViewModel] in
                Task { @MainActor in await detailViewModel?.refreshLowStockThreshold() }
            })
        let vc = AuthenticatedWebViewController(viewModel: webModel)
        navigationController?.pushViewController(vc, animated: true)
    }
}

private extension NewStockNotificationPreferencesHostingController {
    enum Localization {
        static let editThresholdWebTitle = NSLocalizedString(
            "newStockNotificationPreferencesHostingController.editThreshold.webTitle",
            value: "Low stock threshold",
            comment: "Title of the authenticated webview shown when the merchant taps 'Edit store-wide threshold' under the Low stock toggle."
        )
    }
}
