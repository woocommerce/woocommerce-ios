import UIKit


/// WooCommerce UIButton Style Helpers
///
extension UIButton {

    /// Applies the Primary Button Style: Solid BG!
    ///
    func applyPrimaryButtonStyle() {
        contentEdgeInsets = Style.defaultEdgeInsets
        layer.borderColor = UIColor.primaryButtonBorder.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
        enableMultipleLines()
        titleLabel?.textAlignment = .center

        setTitleColor(.primaryButtonTitle, for: .normal)
        setTitleColor(.primaryButtonTitle, for: .highlighted)
        setTitleColor(.buttonDisabledTitle, for: .disabled)

        let normalBackgroundImage = UIImage.renderBackgroundImage(fill: .primaryButtonBackground,
                                                                  border: .primaryButtonBorder)
            .applyTintColorToiOS13(.primaryButtonBackground)
        setBackgroundImage(normalBackgroundImage, for: .normal)

        let highlightedBackgroundImage = UIImage.renderBackgroundImage(fill: .primaryButtonDownBackground,
                                                                       border: .primaryButtonDownBorder)
            .applyTintColorToiOS13(.primaryButtonDownBackground)
        setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        let disabledBackgroundImage = UIImage.renderBackgroundImage(fill: .buttonDisabledBackground,
                                                                    border: .buttonDisabledBorder)
            .applyTintColorToiOS13(.buttonDisabledBorder) // Use border as tint color since the background is clear
        setBackgroundImage(disabledBackgroundImage, for: .disabled)
    }

    /// Applies the Secondary Button Style: Clear BG / Bordered Outline
    ///
    func applySecondaryButtonStyle() {
        backgroundColor = .secondaryButtonBackground
        contentEdgeInsets = Style.defaultEdgeInsets
        layer.borderColor = UIColor.secondaryButtonBorder.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
        enableMultipleLines()
        titleLabel?.textAlignment = .center

        setTitleColor(.secondaryButtonTitle, for: .normal)
        setTitleColor(.secondaryButtonTitle, for: .highlighted)
        setTitleColor(.buttonDisabledTitle, for: .disabled)

        let normalBackgroundImage = UIImage.renderBackgroundImage(fill: .secondaryButtonBackground,
                                                                  border: .secondaryButtonBorder)
            .applyTintColorToiOS13(.secondaryButtonBackground)
        setBackgroundImage(normalBackgroundImage, for: .normal)

        let highlightedBackgroundImage = UIImage.renderBackgroundImage(fill: .secondaryButtonDownBackground,
                                                                       border: .secondaryButtonDownBorder)
            .applyTintColorToiOS13(.secondaryButtonDownBackground)
        setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        let disabledBackgroundImage = UIImage.renderBackgroundImage(fill: .buttonDisabledBackground,
                                                                    border: .buttonDisabledBorder)
            .applyTintColorToiOS13(.buttonDisabledBackground)
        setBackgroundImage(disabledBackgroundImage, for: .disabled)
    }

    /// Applies the Link Button Style: Clear BG / Brand Text Color
    ///
    func applyLinkButtonStyle(enableMultipleLines: Bool = false) {
        backgroundColor = .clear
        contentEdgeInsets = Style.defaultEdgeInsets
        tintColor = .accent
        titleLabel?.applyBodyStyle()
        titleLabel?.textAlignment = .natural

        if enableMultipleLines {
            self.enableMultipleLines()
        }

        setTitleColor(.accent, for: .normal)
        setTitleColor(.accentDark, for: .highlighted)
    }

    /// Applies the Modal Cancel Button Style
    ///
    func applyModalCancelButtonStyle() {
        backgroundColor = .clear
        titleLabel?.applyBodyStyle()
        titleLabel?.textAlignment = .natural
        setTitleColor(.modalCancelAction, for: .normal)
    }

    func applyPaymentsModalCancelButtonStyle() {
        backgroundColor = .tertiarySystemBackground
        contentEdgeInsets = Style.defaultEdgeInsets
        layer.borderColor = UIColor.secondaryButtonBorder.cgColor
        layer.borderWidth = Style.defaultBorderWidth
        layer.cornerRadius = Style.defaultCornerRadius
        titleLabel?.applyHeadlineStyle()
        enableMultipleLines()
        titleLabel?.textAlignment = .center

        setTitleColor(.secondaryButtonTitle, for: .normal)
        setTitleColor(.secondaryButtonTitle, for: .highlighted)
        setTitleColor(.buttonDisabledTitle, for: .disabled)

        let normalBackgroundImage = UIImage.renderBackgroundImage(fill: .tertiarySystemBackground,
                                                                  border: .secondaryButtonBorder)
            .applyTintColorToiOS13(.tertiarySystemBackground)
        setBackgroundImage(normalBackgroundImage, for: .normal)

        let highlightedBackgroundImage = UIImage.renderBackgroundImage(fill: .secondaryButtonDownBackground,
                                                                       border: .secondaryButtonDownBorder)
            .applyTintColorToiOS13(.secondaryButtonDownBackground)
        setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        let disabledBackgroundImage = UIImage.renderBackgroundImage(fill: .buttonDisabledBackground,
                                                                    border: .buttonDisabledBorder)
            .applyTintColorToiOS13(.buttonDisabledBackground)
        setBackgroundImage(disabledBackgroundImage, for: .disabled)
    }

    /// Applies the Single-Color Icon Button Style: accent/accent dark tint color
    ///
    func applyIconButtonStyle(icon: UIImage) {
        let normalImage = icon.applyTintColor(.accent)
        let highlightedImage = icon.applyTintColor(.accentDark)
        setImage(normalImage, for: .normal)
        setImage(highlightedImage, for: .highlighted)
        tintColor = .accent
    }

    /// By default UIButton adds an animation when changing the title. Use this method to avoid that
    /// 
    func setTitleWithoutAnimation(_ title: String?, for state: UIControl.State) {
        UIView.performWithoutAnimation {
            setTitle(title, for: .normal)
            layoutIfNeeded()
        }
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
    }
}
