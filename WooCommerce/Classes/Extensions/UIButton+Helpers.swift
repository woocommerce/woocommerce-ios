import UIKit


/// WooCommerce UIButton Style Helpers
///
extension UIButton {

    /// Applies the Primary Button Style: Solid BG!
    ///
    func applyPrimaryButtonStyle() {
        backgroundColor = StyleManager.wooCommerceBrandColor
        contentEdgeInsets = Style.defaultEdgeInsets
        tintColor = .white
        layer.borderColor = StyleManager.wooCommerceBrandColor.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
    }

    /// Applies the Secondary Button Style: Clear BG / Bordered Outline
    ///
    func applySecondaryButtonStyle() {
        backgroundColor = .clear
        contentEdgeInsets = Style.defaultEdgeInsets
        tintColor = StyleManager.wooCommerceBrandColor
        layer.borderColor = StyleManager.wooCommerceBrandColor.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
    }

    /// Applies the Terciary Button Style: Clear BG / Top Outline
    ///
    func applyTertiaryButtonStyle() {
        backgroundColor = .clear
        contentEdgeInsets = Style.noMarginEdgeInsets
        tintColor = StyleManager.wooCommerceBrandColor
        layer.borderColor = StyleManager.wooCommerceBrandColor.cgColor
        titleLabel?.applySubheadlineStyle()
        titleLabel?.textAlignment = .natural
    }

    /// Supports title of multiple lines, either from longer text than allocated width or text with line breaks.
    func enableMultipleLines() {
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
