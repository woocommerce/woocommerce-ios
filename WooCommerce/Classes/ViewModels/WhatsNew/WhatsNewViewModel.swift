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

    init(items: [ReportItem], onDismiss: @escaping () -> Void) {
        self.items = items
        self.onDismiss = onDismiss
    }
}

// MARK: - Localization
private extension WhatsNewViewModel {
    enum Localization {
        static let title = NSLocalizedString("What’s New in WooCommerce", comment: "Title of Whats New Component")
        static let ctaTitle = NSLocalizedString("Continue", comment: "Title of continue button")
    }
}
