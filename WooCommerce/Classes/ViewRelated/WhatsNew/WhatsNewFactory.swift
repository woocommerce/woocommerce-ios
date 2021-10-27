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
            ReportItem(title: $0.title, subtitle: $0.subtitle, icon: icon(for: $0))
        }
    }

    /// Get IconListItem.Icon from a Feature
    private static func icon(for feature: Feature) -> IconListItem.Icon? {
        var icon: IconListItem.Icon?
        if let base64String = feature.iconBase64?.components(separatedBy: ";base64,")[safe: 1],
           let imageData = Data(base64Encoded: base64String),
           let image = UIImage(data: imageData) {
            icon = .base64(image)
        } else if let url = URL(string: feature.iconUrl) {
            icon = .remote(url)
        }
        return icon
    }
}
