import UIKit


/// WooCommerce UIButton Style Helpers
///
extension UIButton {

    /// Applies the Primary Button Style: Solid BG!
    ///
    func applyPrimaryButtonStyle() {
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(
            top: Style.verticalInset,
            leading: Style.horizontalInset,
            bottom: Style.verticalInset,
            trailing: Style.horizontalInset
        )
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
            .withTintColor(.primaryButtonBackground)
        setBackgroundImage(normalBackgroundImage, for: .normal)

        let highlightedBackgroundImage = UIImage.renderBackgroundImage(fill: .primaryButtonDownBackground,
                                                                       border: .primaryButtonDownBorder)
            .withTintColor(.primaryButtonDownBackground)
        setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        let disabledBackgroundImage = UIImage.renderBackgroundImage(fill: .buttonDisabledBackground,
                                                                    border: .buttonDisabledBorder)
            .withTintColor(.buttonDisabledBorder) // Use border as tint color since the background is clear
        setBackgroundImage(disabledBackgroundImage, for: .disabled)
    }

    /// Applies the Secondary Button Style: Clear BG / Bordered Outline
    ///
    func applySecondaryButtonStyle() {
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(
            top: Style.verticalInset,
            leading: Style.horizontalInset,
            bottom: Style.verticalInset,
            trailing: Style.horizontalInset
        )
        backgroundColor = .secondaryButtonBackground
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
            .withTintColor(.secondaryButtonBackground)
        setBackgroundImage(normalBackgroundImage, for: .normal)

        let highlightedBackgroundImage = UIImage.renderBackgroundImage(fill: .secondaryButtonDownBackground,
                                                                       border: .secondaryButtonDownBorder)
            .withTintColor(.secondaryButtonDownBackground)
        setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        let disabledBackgroundImage = UIImage.renderBackgroundImage(fill: .buttonDisabledBackground,
                                                                    border: .buttonDisabledBorder)
            .withTintColor(.buttonDisabledBackground)
        setBackgroundImage(disabledBackgroundImage, for: .disabled)
    }

    /// Applies the Link Button Style: Clear BG / Brand Text Color
    ///
    func applyLinkButtonStyle(enableMultipleLines: Bool = false) {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .init(
            top: Style.verticalInset,
            leading: Style.horizontalInset,
            bottom: Style.verticalInset,
            trailing: Style.horizontalInset
        )
        backgroundColor = .clear
        tintColor = .accent
        titleLabel?.applyBodyStyle()
        titleLabel?.textAlignment = .natural

        if enableMultipleLines {
            self.enableMultipleLines()
        }

        setTitleColor(.accent, for: .normal)
        setTitleColor(.accentDark, for: .highlighted)
        setTitleColor(.buttonDisabledTitle, for: .disabled)
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
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .init(
            top: Style.verticalInset,
            leading: Style.horizontalInset,
            bottom: Style.verticalInset,
            trailing: Style.horizontalInset
        )
        backgroundColor = .tertiarySystemBackground
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
            .withTintColor(.tertiarySystemBackground)
        setBackgroundImage(normalBackgroundImage, for: .normal)

        let highlightedBackgroundImage = UIImage.renderBackgroundImage(fill: .secondaryButtonDownBackground,
                                                                       border: .secondaryButtonDownBorder)
            .withTintColor(.secondaryButtonDownBackground)
        setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        let disabledBackgroundImage = UIImage.renderBackgroundImage(fill: .buttonDisabledBackground,
                                                                    border: .buttonDisabledBorder)
            .withTintColor(.buttonDisabledBackground)
        setBackgroundImage(disabledBackgroundImage, for: .disabled)
    }

    /// Applies the Single-Color Icon Button Style: accent/accent dark tint color
    ///
    func applyIconButtonStyle(icon: UIImage) {
        let normalImage = icon.withTintColor(.accent)
        let highlightedImage = icon.withTintColor(.accentDark)
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
            if self.subviews.contains(where: { $0 == label }) {
                pinSubviewToAllEdgeMargins(label)
            } else {
                DDLogWarn("""
                    Failed attempt to pin button's title to the edges.
                    This is likely because the custom button title label was not added to its view hierarchy.
                    """
                )
            }
        }
    }
}


// MARK: - Private Structures
//
private extension UIButton {

    struct Style {
        static let defaultCornerRadius = CGFloat(8.0)
        static let defaultBorderWidth = CGFloat(1.0)
        static let verticalInset = CGFloat(12)
        static let horizontalInset = CGFloat(22)
    }
}
