import SwiftUI
import Yosemite

struct WhatsNewFactory {
    /// Creates a What's New view controller for a given announcement
    ///
    /// - Parameters:
    ///   - announcement: Announcement model
    ///   - onDismiss: called when the CTA button is pressed, mainly for dismissing the screen
    static func whatsNew(_ announcement: Announcement,
                         onDismiss: @escaping () -> Void) -> UIViewController {

        let viewModel = WhatsNewViewModel(items: announcement.features, onDismiss: onDismiss)
        let rootView = ReportListView(viewModel: viewModel)
        let hostingViewController = UIHostingController(rootView: rootView)
        if UIDevice.isPad() {
            hostingViewController.preferredContentSize = CGSize(width: 360, height: 574)
        }
        hostingViewController.modalPresentationStyle = .formSheet
        return hostingViewController
    }
}
