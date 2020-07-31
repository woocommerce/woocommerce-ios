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

    public let navBarBackgroundColor: UIColor
    
    public let navButtonTextColor: UIColor

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
    public init(primaryNormalBackgroundColor: UIColor,
                primaryNormalBorderColor: UIColor?,
                primaryHighlightBackgroundColor: UIColor,
                primaryHighlightBorderColor: UIColor?,
                secondaryNormalBackgroundColor: UIColor,
                secondaryNormalBorderColor: UIColor,
                secondaryHighlightBackgroundColor: UIColor,
                secondaryHighlightBorderColor: UIColor,
                disabledBackgroundColor: UIColor,
                disabledBorderColor: UIColor,
                primaryTitleColor: UIColor,
                secondaryTitleColor: UIColor,
                disabledTitleColor: UIColor,
                textButtonColor: UIColor,
                textButtonHighlightColor: UIColor,
                instructionColor: UIColor,
                subheadlineColor: UIColor,
                placeholderColor: UIColor,
                viewControllerBackgroundColor: UIColor,
                textFieldBackgroundColor: UIColor,
                buttonViewBackgroundColor: UIColor? = nil,
                navBarImage: UIImage,
                navBarBadgeColor: UIColor,
                navBarBackgroundColor: UIColor,
                navButtonTextColor: UIColor = .white,
                prologueBackgroundColor: UIColor = WPStyleGuide.wordPressBlue(),
                prologueTitleColor: UIColor = .white,
                statusBarStyle: UIStatusBarStyle = .lightContent) {
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
        self.navBarBackgroundColor = navBarBackgroundColor
        self.navButtonTextColor = navButtonTextColor
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

    /// Style Auth default error color
    ///
    public let errorColor: UIColor

    /// Style: Auth default text color
    ///
    public let textColor: UIColor

    /// Style: Auth subtle text color
    ///
    public let textSubtleColor: UIColor

    /// Style: Auth plain text button normal state color
    ///
    public let textButtonColor: UIColor

    /// Style: Auth plain text button highlight state color
    ///
    public let textButtonHighlightColor: UIColor

    /// Style: Auth view background colors
    ///
    public let viewControllerBackgroundColor: UIColor

    /// Style: Status bar style. Defaults to `default`.
    ///
    public let statusBarStyle: UIStatusBarStyle
    
    /// Style: Navigation bar.
    ///
    public let navBarBackgroundColor: UIColor
    public let navButtonTextColor: UIColor
    public let navTitleTextColor: UIColor
    
    /// Designated initializer
    ///
    public init(borderColor: UIColor,
                errorColor: UIColor,
                textColor: UIColor,
                textSubtleColor: UIColor,
                textButtonColor: UIColor,
                textButtonHighlightColor: UIColor,
                viewControllerBackgroundColor: UIColor,
                statusBarStyle: UIStatusBarStyle = .default,
                navBarBackgroundColor: UIColor,
                navButtonTextColor: UIColor,
                navTitleTextColor: UIColor) {
        self.borderColor = borderColor
        self.errorColor = errorColor
        self.textColor = textColor
        self.textSubtleColor = textSubtleColor
        self.textButtonColor = textButtonColor
        self.textButtonHighlightColor = textButtonHighlightColor
        self.viewControllerBackgroundColor = viewControllerBackgroundColor
        self.statusBarStyle = statusBarStyle
        self.navBarBackgroundColor = navBarBackgroundColor
        self.navButtonTextColor = navButtonTextColor
        self.navTitleTextColor = navTitleTextColor
    }
}
