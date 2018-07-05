import UIKit
import WordPressShared
import WordPressUI

/// A protocol for an element that can display a UIActivityIndicatorView
@objc public protocol ActivityIndicatorButton {
    func showActivityIndicator(_ show: Bool)
}

/// A stylized button used by Login controllers. It also can display a `UIActivityIndicatorView`.
@objc open class NUXButton: UIButton, ActivityIndicatorButton {
    @objc var isAnimating: Bool {
        get {
            return activityIndicator.isAnimating
        }
    }

    @objc let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
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
            activityIndicator.frame = frm
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
        configureBackgrounds()
        configureTitleColors()
        setNeedsLayout()
    }

    func didChangePreferredContentSize() {
        titleLabel?.adjustsFontForContentSizeCategory = true
    }


    // MARK: UIAppearance Customizations
    /// Style: Primary + Normal State
    ///
    @objc public dynamic var primaryNormalBackgroundColor = Primary.normalBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var primaryNormalBorderColor = Primary.normalBorderColor {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Primary + Highlighted State
    ///
    @objc public dynamic var primaryHighlightBackgroundColor = Primary.highlightBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var primaryHighlightBorderColor = Primary.highlightBorderColor {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Secondary
    ///
    @objc public dynamic var secondaryNormalBackgroundColor = Secondary.normalBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var secondaryNormalBorderColor = Secondary.normalBorderColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var secondaryHighlightBackgroundColor = Secondary.highlightBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var secondaryHighlightBorderColor = Secondary.highlightBorderColor {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Disabled State
    ///
    @objc public dynamic var disabledBackgroundColor = Disabled.backgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var disabledBorderColor = Disabled.borderColor {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Title!
    ///
    @objc public dynamic var titleFont = Title.defaultFont {
        didSet {
            configureTitleLabel()
        }
    }
    @objc public dynamic var primaryTitleColor = Title.primaryColor {
        didSet {
            configureTitleColors()
        }
    }
    @objc public dynamic var secondaryTitleColor = Title.secondaryColor {
        didSet {
            configureTitleColors()
        }
    }
    @objc public dynamic var disabledTitleColor = Title.disabledColor {
        didSet {
            configureTitleColors()
        }
    }

    /// Insets to be applied over the Contents.
    ///
    @objc public dynamic var contentInsets = UIImage.DefaultRenderMetrics.contentInsets {
        didSet {
            configureInsets()
        }
    }

    /// Indicates if the current instance should be rendered with the "Primary" Style.
    ///
    @IBInspectable var isPrimary: Bool = false {
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
    }


    /// Setup: Everything = [Insets, Backgrounds, titleColor(s), titleLabel]
    ///
    private func configureAppearance() {
        configureInsets()
        configureBackgrounds()
        configureTitleColors()
        configureTitleLabel()
    }

    /// Setup: FancyButton's Default Settings
    ///
    private func configureInsets() {
        contentEdgeInsets = contentInsets
    }

    /// Setup: BackgroundImage
    ///
    private func configureBackgrounds() {
        let normalImage: UIImage
        let highlightedImage: UIImage
        let disabledImage = UIImage.renderBackgroundImage(fill: disabledBackgroundColor, border: disabledBorderColor, shadowOffset: Metrics.backgroundShadowOffset)

        if isPrimary {
            normalImage = UIImage.renderBackgroundImage(fill: primaryNormalBackgroundColor, border: primaryNormalBorderColor, shadowOffset: Metrics.backgroundShadowOffset)
            highlightedImage = UIImage.renderBackgroundImage(fill: primaryHighlightBackgroundColor, border: primaryHighlightBorderColor, shadowOffset: Metrics.backgroundShadowOffset)
        } else {
            normalImage = UIImage.renderBackgroundImage(fill: secondaryNormalBackgroundColor, border: secondaryNormalBorderColor, shadowOffset: Metrics.backgroundShadowOffset)
            highlightedImage = UIImage.renderBackgroundImage(fill: secondaryHighlightBackgroundColor, border: secondaryHighlightBorderColor, shadowOffset: Metrics.backgroundShadowOffset)
        }

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightedImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)

        activityIndicator.activityIndicatorViewStyle = .gray
        addSubview(activityIndicator)
    }

    /// Setup: TitleColor
    ///
    private func configureTitleColors() {
        let titleColorNormal = isPrimary ? primaryTitleColor : secondaryTitleColor

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(disabledTitleColor, for: .disabled)
    }

    /// Setup: TitleLabel
    ///
    private func configureTitleLabel() {
        titleLabel?.font = titleFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center
    }
}

// MARK: - Nested types
private extension NUXButton {
    /// Style: Primary
    ///
    struct Primary {
        static let normalBackgroundColor = WPStyleGuide.mediumBlue()
        static let normalBorderColor = WPStyleGuide.wordPressBlue()
        static let highlightBackgroundColor = WPStyleGuide.wordPressBlue()
        static let highlightBorderColor = normalBorderColor
    }

    /// Style: Secondary
    ///
    struct Secondary {
        static let normalBackgroundColor = UIColor.white
        static let normalBorderColor = WPStyleGuide.greyLighten20()
        static let highlightBackgroundColor = WPStyleGuide.greyLighten20()
        static let highlightBorderColor = highlightBackgroundColor
    }

    /// Style: Disabled
    ///
    struct Disabled {
        static let backgroundColor = UIColor.white
        static let borderColor = WPStyleGuide.greyLighten30()
    }

    /// Style: Title
    ///
    struct Title {
        static let primaryColor = UIColor.white
        static let secondaryColor = WPStyleGuide.darkGrey()
        static let disabledColor = WPStyleGuide.greyLighten30()
        static let defaultFont = WPFontManager.systemSemiBoldFont(ofSize: 17.0)
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

    struct Metrics {
        static let backgroundShadowOffset = CGSize(width: 0, height: 2)
    }
}
