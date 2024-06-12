import Foundation
import UIKit


/// UITableViewCell Helpers
///
extension UITableViewCell {

    /// Returns a reuseIdentifier that matches the receiver's classname (non namespaced).
    ///
    class var reuseIdentifier: String {
        return classNameWithoutNamespaces
    }

    /// Configures the default background configuration
    func configureDefaultBackgroundConfiguration() {
        var backgroundConfiguration = defaultBackgroundConfiguration()
        backgroundConfiguration.backgroundColor = .listForeground(modal: false)
        self.backgroundConfiguration = backgroundConfiguration
    }

    /// Updates the default background configuration
    func updateDefaultBackgroundConfiguration(using state: UICellConfigurationState, style: UITableView.Style = .grouped) {
        var backgroundConfiguration = defaultBackgroundConfiguration().updated(for: state)
        if style == .grouped {
            backgroundConfiguration.backgroundColor = .listForeground(modal: false)
        }

        if state.isSelected || state.isHighlighted {
            backgroundConfiguration.backgroundColor = .listSelectedBackground
            backgroundConfiguration.strokeColor = Layout.borderStrokeColor
            backgroundConfiguration.strokeWidth = Layout.borderorderStrokeWidth
        }
        self.backgroundConfiguration = backgroundConfiguration
    }

    /// Hides the separator for a cell.
    /// Be careful applying this to a reusable cell where the separator is expected to be shown in some cases.
    ///
    func hideSeparator() {
        // Using `CGFloat.greatestFiniteMagnitude` for the right separator inset would not work if the cell is initially configured with `hideSeparator()` then
        // updated with `showSeparator()` later after the table view is rendered - the separator would not be shown again.
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 999999)
    }

    /// Shows the separator for a cell.
    /// The separator inset is only set manually when a custom inset is preferred, or the cell is reusable with a different inset in other use cases.
    ///
    func showSeparator(inset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 0)) {
        separatorInset = inset
    }
}

private extension UITableViewCell {
    enum Layout {
        static let borderStrokeColor: UIColor = .divider
        static let borderorderStrokeWidth: CGFloat = 0.5
    }
}
