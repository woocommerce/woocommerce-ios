import Foundation
import Yosemite

/// View model used to fill up the What's New Component, map from Features to ReportItems and dispatch analytics events
final class WhatsNewViewModel: ReportListPresentable {
    /// List of items to be displayed in the report list
    let items: [ReportItem]

    /// Closure that is called when CTA button is pressed
    let onDismiss: () -> Void

    /// Title of the What's New screen
    let title = Localization.title

    /// Title of the Call to action button
    let ctaTitle = Localization.ctaTitle

    /// StoresManager that will be handling actions
    private let stores: StoresManager

    init(items: [ReportItem], stores: StoresManager = ServiceLocator.stores, onDismiss: @escaping () -> Void) {
        self.items = items
        self.stores = stores
        self.onDismiss = onDismiss
    }

    func onAppear() {
        stores.dispatch(AnnouncementsAction.markSavedAnnouncementAsDisplayed(onCompletion: { result in
            switch result {
            case .success:
                DDLogInfo("📣 Announcement was marked as displayed! ✅")
            case .failure(let error):
                DDLogError("⛔️ Failed to mark announcement as displayed: \(error.localizedDescription)")
            }
        }))
    }
}

// MARK: - Localization
private extension WhatsNewViewModel {
    enum Localization {
        static let title = NSLocalizedString("What’s New in WooCommerce", comment: "Title of Whats New Component")
        static let ctaTitle = NSLocalizedString("Continue", comment: "Title of continue button")
    }
}
