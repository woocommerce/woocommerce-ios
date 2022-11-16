import UIKit


/// WooCommerce UIButton Style Helpers
///
extension UIButton {

    /// Applies the Primary Button Style: Solid BG!
    ///
    func applyPrimaryButtonStyle() {
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(
            top: Style.defaultVerticalInsets,
            leading: Style.defaultHorizontalInsets,
            bottom: Style.defaultVerticalInsets,
            trailing: Style.defaultHorizontalInsets
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
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(
            top: Style.defaultVerticalInsets,
            leading: Style.defaultHorizontalInsets,
            bottom: Style.defaultVerticalInsets,
            trailing: Style.defaultHorizontalInsets
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
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .init(
            top: Style.defaultVerticalInsets,
            leading: Style.defaultHorizontalInsets,
            bottom: Style.defaultVerticalInsets,
            trailing: Style.defaultHorizontalInsets
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
            top: Style.defaultVerticalInsets,
            leading: Style.defaultHorizontalInsets,
            bottom: Style.defaultVerticalInsets,
            trailing: Style.defaultHorizontalInsets
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
            if self.subviews.contains(where: { $0 == label }) {
                pinSubviewToAllEdgeMargins(label)
            } else {
                DDLogWarn("""
                    Failed attempt to pin button's title to the edges.
                    This is likely because the custom button title label was not added to its view hierarchy
                    See ButtonActivityIndicator as an example
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
        static let defaultVerticalInsets = CGFloat(12)
        static let defaultHorizontalInsets = CGFloat(22)
    }
}
