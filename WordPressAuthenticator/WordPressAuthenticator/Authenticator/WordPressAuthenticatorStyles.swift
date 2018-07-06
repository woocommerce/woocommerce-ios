

// MARK: - WordPress Authenticator Styles
//
public struct WordPressAuthenticatorStyle {
    /// Style: Primary + Normal State
    ///
    public let primaryNormalBackgroundColor: UIColor

    public let primaryNormalBorderColor: UIColor

    /// Style: Primary + Highlighted State
    ///
    public let primaryHighlightBackgroundColor: UIColor

    public let primaryHighlightBorderColor: UIColor

    /// Style: Secondary
    ///
    public let secondaryNormalBackgroundColor: UIColor

    public let secondaryNormalBorderColor: UIColor

    public let secondaryHighlightBackgroundColor: UIColor

    public let secondaryHighlightBorderColor: UIColor

    /// Style: Disabled State
    ///
    public let disabledBackgroundColor: UIColor

    public let disabledBorderColor: UIColor

    /// Style: Title!
    ///
    public let titleFont: UIFont

    public let primaryTitleColor: UIColor

    public let secondaryTitleColor: UIColor

    public let disabledTitleColor: UIColor

    /// Designated initializer
    ///
    public init(primaryNormalBackgroundColor: UIColor, primaryNormalBorderColor: UIColor, primaryHighlightBackgroundColor: UIColor, primaryHighlightBorderColor: UIColor, secondaryNormalBackgroundColor: UIColor, secondaryNormalBorderColor: UIColor, secondaryHighlightBackgroundColor: UIColor, secondaryHighlightBorderColor: UIColor, disabledBackgroundColor: UIColor, disabledBorderColor: UIColor, titleFont: UIFont, primaryTitleColor: UIColor, secondaryTitleColor: UIColor, disabledTitleColor: UIColor) {
        self.primaryNormalBackgroundColor = primaryNormalBackgroundColor
        self.primaryNormalBorderColor = primaryNormalBorderColor
        self.primaryHighlightBackgroundColor = primaryHighlightBackgroundColor
        self.primaryHighlightBorderColor = primaryHighlightBorderColor
        self.secondaryNormalBackgroundColor = secondaryNormalBackgroundColor
        self.secondaryNormalBorderColor = secondaryNormalBorderColor
        self.secondaryHighlightBackgroundColor = secondaryHighlightBackgroundColor
        self.secondaryHighlightBorderColor = secondaryHighlightBorderColor
        self.disabledBackgroundColor = disabledBackgroundColor
        self.disabledBorderColor = disabledBorderColor
        self.titleFont = titleFont
        self.primaryTitleColor = primaryTitleColor
        self.secondaryTitleColor = primaryTitleColor
        self.disabledTitleColor = disabledTitleColor
    }
}

public extension WordPressAuthenticatorStyle {
    public static var defaultStyle: WordPressAuthenticatorStyle {
        return WordPressAuthenticatorStyle(primaryNormalBackgroundColor: WPStyleGuide.mediumBlue(),
                                           primaryNormalBorderColor: WPStyleGuide.wordPressBlue(),
                                           primaryHighlightBackgroundColor: WPStyleGuide.wordPressBlue(),
                                           primaryHighlightBorderColor: WPStyleGuide.wordPressBlue(),
                                           secondaryNormalBackgroundColor: UIColor.white,
                                           secondaryNormalBorderColor: WPStyleGuide.greyLighten20(),
                                           secondaryHighlightBackgroundColor: WPStyleGuide.greyLighten20(),
                                           secondaryHighlightBorderColor: WPStyleGuide.greyLighten20(),
                                           disabledBackgroundColor: UIColor.white,
                                           disabledBorderColor: WPStyleGuide.greyLighten30(),
                                           titleFont: WPFontManager.systemSemiBoldFont(ofSize: 17.0),
                                           primaryTitleColor: UIColor.white,
                                           secondaryTitleColor: WPStyleGuide.darkGrey(),
                                           disabledTitleColor: WPStyleGuide.greyLighten30())
    }
}
