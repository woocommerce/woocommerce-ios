import UIKit
import WooFoundation

/// Properties for the bottom sheet list selector view.
///
struct BottomSheetListSelectorViewProperties {
    let title: String?
    let subtitle: String?
    let accessibilityIdentifier: String?
    let backgroundColor: UIColor

    init(title: String? = nil,
         subtitle: String? = nil,
         accessibilityIdentifier: String? = nil,
         backgroundColor: UIColor = .listForeground(modal: false)) {
        self.title = title
        self.subtitle = subtitle
        self.accessibilityIdentifier = accessibilityIdentifier
        self.backgroundColor = backgroundColor
    }
}
