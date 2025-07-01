import UIKit

extension UILabel {
    /// Applies the appropriate style to sales channel label
    ///
    func applySalesChannelStyle() {
        applyFootnoteStyle()
        applyLayerSettings()
        backgroundColor = .lightGray
        textColor = .black
    }

    /// Setup: Layer
    ///
    private func applyLayerSettings() {
        layer.masksToBounds = true
        layer.borderWidth = Layout.borderWidth
        layer.cornerRadius = Layout.cornerRadius
    }
}

private extension UILabel {
    enum Layout {
        static let borderWidth = CGFloat(0.0)
        static let cornerRadius = CGFloat(4.0)
    }
}
