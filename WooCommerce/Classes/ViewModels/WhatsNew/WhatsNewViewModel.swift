import Foundation
import Yosemite

/// View model used to fill up the What's New Component, map from Features to ReportItems and dispatch analytics events
final class WhatsNewViewModel: ReportListPresentable {
    let items: [ReportItem]
    let onDismiss: () -> Void
    let title = NSLocalizedString("What’s New in WooCommerce", comment: "Title of Whats New Component")
    let ctaTitle = NSLocalizedString("Continue", comment: "Title of continue button")

    init(items: [Feature], onDismiss: @escaping () -> Void) {
        self.items = items.map { ReportItem(title: $0.title, subtitle: $0.subtitle, iconUrl: $0.iconUrl, iconBase64: $0.iconBase64)}
        self.onDismiss = onDismiss
    }
}
