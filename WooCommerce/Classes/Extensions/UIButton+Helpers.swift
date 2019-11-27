import UIKit


/// WooCommerce UIButton Style Helpers
///
extension UIButton {

    /// Applies the Primary Button Style: Solid BG!
    ///
    func applyPrimaryButtonStyle() {
        backgroundColor = .primary
        contentEdgeInsets = Style.defaultEdgeInsets
        tintColor = .primaryButtonBackground
        layer.borderColor = UIColor.primary.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
        enableMultipleLines()
        titleLabel?.textAlignment = .center
    }

    /// Applies the Secondary Button Style: Clear BG / Bordered Outline
    ///
    func applySecondaryButtonStyle() {
        backgroundColor = .clear
        contentEdgeInsets = Style.defaultEdgeInsets
        tintColor = .primary
        layer.borderColor = UIColor.primary.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
        enableMultipleLines()
        titleLabel?.textAlignment = .center
    }

    /// Applies the Tertiary Button Style: Clear BG / Top Outline
    ///
    func applyTertiaryButtonStyle() {
        backgroundColor = .clear
        contentEdgeInsets = Style.noMarginEdgeInsets
        tintColor = .primary
        layer.borderColor = UIColor.primary.cgColor
        titleLabel?.applySubheadlineStyle()
        titleLabel?.textAlignment = .natural
    }

    /// Applies the Link Button Style: Clear BG / Brand Text Color
    ///
    func applyLinkButtonStyle() {
        backgroundColor = .clear
        contentEdgeInsets = Style.defaultEdgeInsets
        tintColor = .primary
        titleLabel?.applyBodyStyle()
        titleLabel?.textAlignment = .natural
        setTitleColor(.primary, for: .normal)
        setTitleColor(UIColor.primary.withAlphaComponent(0.5), for: .highlighted)
    }

    /// Supports title of multiple lines, either from longer text than allocated width or text with line breaks.
    private func enableMultipleLines() {
        titleLabel?.lineBreakMode = .byWordWrapping
        if let label = titleLabel {
            pinSubviewToAllEdgeMargins(label)
        }
    }
}


// MARK: - Private Structures
//
private extension UIButton {

    struct Style {
        static let defaultCornerRadius = CGFloat(8.0)
        static let defaultBorderWidth = CGFloat(1.0)
        static let defaultEdgeInsets = UIEdgeInsets(top: 12, left: 22, bottom: 12, right: 22)
        static let noMarginEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
}
