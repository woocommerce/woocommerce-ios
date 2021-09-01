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

        let items = mapFeaturesToItems(announcement.features)
        let viewModel = WhatsNewViewModel(items: items, onDismiss: onDismiss)
        let rootView = ReportList(viewModel: viewModel)
        let hostingViewController = WhatsNewHostingController(rootView: rootView)
        return hostingViewController
    }

    /// Transform Features into ReportItem models
    private static func mapFeaturesToItems(_ features: [Feature]) -> [ReportItem] {
        features.map {
            var icon: IconListItem.Icon?
            if let base64String = $0.iconBase64,
               let imageData = Data(base64Encoded: base64String),
               let image = UIImage(data: imageData) {
                icon = .base64(image)
            } else if let url = URL(string: $0.iconUrl) {
                icon = .remote(url)
            }
            return ReportItem(title: $0.title, subtitle: $0.subtitle, icon: icon)
        }
    }
}
