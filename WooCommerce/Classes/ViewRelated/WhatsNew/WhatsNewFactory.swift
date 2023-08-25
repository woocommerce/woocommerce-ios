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

        if let icons = feature.icons,
           let lightIcon = icons.first(where: { $0.iconType == "light" }) {
            let darkIcon = icons.first(where: { $0.iconType == "dark" })

            if let lightImage = image(fromBase64: lightIcon.iconBase64) {
                let darkImage = image(fromBase64: darkIcon?.iconBase64)
                icon = .adaptiveBase64(anyAppearance: lightImage, dark: darkImage)
            } else if let lightUrl = URL(string: lightIcon.iconUrl) {
                let darkUrl = URL(string: darkIcon?.iconUrl ?? "")
                icon = .adaptiveRemote(anyAppearance: lightUrl, dark: darkUrl)
            }
        } else if let image = image(fromBase64: feature.iconBase64) {
            icon = .base64(image)
        } else if let url = URL(string: feature.iconUrl) {
            icon = .remote(url)
        }
        return icon
    }

    private static func image(fromBase64 base64String: String?) -> UIImage? {
        guard let base64String,
              let imageURL = URL(string: base64String),
              let imageData = try? Data(contentsOf: imageURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}
