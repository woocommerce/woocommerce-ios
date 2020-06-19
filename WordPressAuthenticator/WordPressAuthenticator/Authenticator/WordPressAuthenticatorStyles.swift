import UIKit
import Gridicons
import WordPressShared

// MARK: - WordPress Authenticator Styles
//
public struct WordPressAuthenticatorStyle {
    /// Style: Primary + Normal State
    ///
    public let primaryNormalBackgroundColor: UIColor

    public let primaryNormalBorderColor: UIColor?

    /// Style: Primary + Highlighted State
    ///
    public let primaryHighlightBackgroundColor: UIColor

    public let primaryHighlightBorderColor: UIColor?

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

    public let primaryTitleColor: UIColor

    public let secondaryTitleColor: UIColor

    public let disabledTitleColor: UIColor

    /// Style: Text Buttons
    ///
    public let textButtonColor: UIColor

    public let textButtonHighlightColor: UIColor

    /// Style: Labels
    ///
    public let instructionColor: UIColor

    public let subheadlineColor: UIColor

    public let placeholderColor: UIColor

    /// Style: Login screen background colors
    ///
    public let viewControllerBackgroundColor: UIColor

    public let textFieldBackgroundColor: UIColor

    // If not specified, falls back to viewControllerBackgroundColor.
    public let buttonViewBackgroundColor: UIColor

    /// Style: nav bar
    ///
    public let navBarImage: UIImage

    public let navBarBadgeColor: UIColor

    /// Style: prologue background colors
    ///
    public let prologueBackgroundColor: UIColor

    /// Style: prologue background colors
    ///
    public let prologueTitleColor: UIColor

    /// Style: status bar style
    ///
    public let statusBarStyle: UIStatusBarStyle

    /// Designated initializer
    ///
    public init(primaryNormalBackgroundColor: UIColor, primaryNormalBorderColor: UIColor?, primaryHighlightBackgroundColor: UIColor, primaryHighlightBorderColor: UIColor?, secondaryNormalBackgroundColor: UIColor, secondaryNormalBorderColor: UIColor, secondaryHighlightBackgroundColor: UIColor, secondaryHighlightBorderColor: UIColor, disabledBackgroundColor: UIColor, disabledBorderColor: UIColor, primaryTitleColor: UIColor, secondaryTitleColor: UIColor, disabledTitleColor: UIColor, textButtonColor: UIColor, textButtonHighlightColor: UIColor, instructionColor: UIColor, subheadlineColor: UIColor, placeholderColor: UIColor, viewControllerBackgroundColor: UIColor, textFieldBackgroundColor: UIColor, buttonViewBackgroundColor: UIColor? = nil, navBarImage: UIImage, navBarBadgeColor: UIColor, prologueBackgroundColor: UIColor = WPStyleGuide.wordPressBlue(), prologueTitleColor: UIColor = .white, statusBarStyle: UIStatusBarStyle = .lightContent) {
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
        self.primaryTitleColor = primaryTitleColor
        self.secondaryTitleColor = secondaryTitleColor
        self.disabledTitleColor = disabledTitleColor
        self.textButtonColor = textButtonColor
        self.textButtonHighlightColor = textButtonHighlightColor
        self.instructionColor = instructionColor
        self.subheadlineColor = subheadlineColor
        self.placeholderColor = placeholderColor
        self.viewControllerBackgroundColor = viewControllerBackgroundColor
        self.textFieldBackgroundColor = textFieldBackgroundColor
        self.buttonViewBackgroundColor = buttonViewBackgroundColor ?? viewControllerBackgroundColor
        self.navBarImage = navBarImage
        self.navBarBadgeColor = navBarBadgeColor
        self.prologueBackgroundColor = prologueBackgroundColor
        self.prologueTitleColor = prologueTitleColor
        self.statusBarStyle = statusBarStyle
    }
}

// MARK: - WordPress Unified Authenticator Styles
//
// Styles specifically for the unified auth flows.
//
public struct WordPressAuthenticatorUnifiedStyle {

    /// Style: Auth view border colors
    ///
    public let borderColor: UIColor

    /// Style: Auth plain text button normal state color
    ///
    public let plainTextButtonColor: UIColor

    /// Style: Auth plain text button highlight state color
    ///
    public let plainTextButtonHighlightColor: UIColor

    /// Style: Auth view background colors
    ///
    public let viewControllerBackgroundColor: UIColor

    /// Designated initializer
    ///
    public init(borderColor: UIColor, plainTextButtonColor: UIColor, plainTextButtonHighlightColor: UIColor, viewControllerBackgroundColor: UIColor) {
        self.borderColor = borderColor
        self.plainTextButtonColor = plainTextButtonColor
        self.plainTextButtonHighlightColor = plainTextButtonHighlightColor
        self.viewControllerBackgroundColor = viewControllerBackgroundColor
    }
}
