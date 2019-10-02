import UIKit
import WordPressShared
import WordPressUI

/// A stylized button used by Login controllers. It also can display a `UIActivityIndicatorView`.
@objc open class NUXButton: UIButton {
    @objc var isAnimating: Bool {
        return activityIndicator.isAnimating
    }

    open override var isEnabled: Bool {
        didSet {
            if #available(iOS 13, *) {
                activityIndicator.color = isEnabled ? style.primaryTitleColor : style.secondaryTitleColor
            }
        }
    }

    @objc let activityIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .white)
        }
        indicator.color = WordPressAuthenticator.shared.style.primaryTitleColor
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override open func layoutSubviews() {
        super.layoutSubviews()

        if activityIndicator.isAnimating {
            titleLabel?.frame = CGRect.zero

            var frm = activityIndicator.frame
            frm.origin.x = (frame.width - frm.width) / 2.0
            frm.origin.y = (frame.height - frm.height) / 2.0
            activityIndicator.frame = frm.integral
        }
    }

    // MARK: - Instance Methods


    /// Toggles the visibility of the activity indicator.  When visible the button
    /// title is hidden.
    ///
    /// - Parameter show: True to show the spinner. False hides it.
    ///
    open func showActivityIndicator(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        setNeedsLayout()
    }

    func didChangePreferredContentSize() {
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    /// Indicates if the current instance should be rendered with the "Primary" Style.
    ///
    @IBInspectable public var isPrimary: Bool = false {
        didSet {
            configureBackgrounds()
            configureTitleColors()
        }
    }


    // MARK: - LifeCycle Methods

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        configureAppearance()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureAppearance()
        guard #available(iOS 13, *) else {
            activityIndicator.style = .gray
            return
        }
    }

    /// Setup: shorter reference for style
    ///
    private let style = WordPressAuthenticator.shared.style

    /// Setup: Everything = [Insets, Backgrounds, titleColor(s), titleLabel]
    ///
    private func configureAppearance() {
        configureInsets()
        configureBackgrounds()
        configureTitleColors()
        configureTitleLabel()
    }

    /// Setup: NUXButton's Default Settings
    ///
    private func configureInsets() {
        contentEdgeInsets = UIImage.DefaultRenderMetrics.contentInsets
    }

    /// Setup: BackgroundImage
    ///
    private func configureBackgrounds() {
        let normalImage: UIImage
        let highlightedImage: UIImage
        let disabledImage = UIImage.renderBackgroundImage(fill: style.disabledBackgroundColor, border: style.disabledBorderColor)

        if isPrimary {
            normalImage = UIImage.renderBackgroundImage(fill: style.primaryNormalBackgroundColor, border: style.primaryNormalBorderColor)
            highlightedImage = UIImage.renderBackgroundImage(fill: style.primaryHighlightBackgroundColor, border: style.primaryHighlightBorderColor)
        } else {
            normalImage = UIImage.renderBackgroundImage(fill: style.secondaryNormalBackgroundColor, border: style.secondaryNormalBorderColor)
            highlightedImage = UIImage.renderBackgroundImage(fill: style.secondaryHighlightBackgroundColor, border: style.secondaryHighlightBorderColor)
        }

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightedImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)

        addSubview(activityIndicator)
    }

    /// Setup: TitleColor
    ///
    private func configureTitleColors() {
        let titleColorNormal = isPrimary ? style.primaryTitleColor : style.secondaryTitleColor

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(style.disabledTitleColor, for: .disabled)
    }

    /// Setup: TitleLabel
    ///
    private func configureTitleLabel() {
        titleLabel?.font = WPFontManager.systemSemiBoldFont(ofSize: 17.0)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center
    }
}

// MARK: -
//
extension NUXButton {
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }

    private struct Metrics {
        static let maxFontSize = CGFloat(22)
    }
}
