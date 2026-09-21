import SwiftUI

/// A trailing icon action of a ``StoreTopAppBar``.
///
/// - Note: Icon-only by design; the accessibility label is required because the glyph is the only
///   visible cue. Keep to one or two essential actions per screen (the design allows three).
public struct StoreTopAppBarAction {
    let icon: StoreIconImage
    let accessibilityLabel: String
    let isEnabled: Bool
    let action: () -> Void

    /// - Parameters:
    ///   - icon: The 24 pt glyph, e.g. `StoreIcon.MagnifyingGlass.regular`.
    ///   - accessibilityLabel: What VoiceOver reads for the control, e.g. "Search".
    ///   - isEnabled: `false` dims the control and blocks its action.
    ///   - action: Runs on tap.
    public init(_ icon: StoreIconImage,
                accessibilityLabel: String,
                isEnabled: Bool = true,
                action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.isEnabled = isEnabled
        self.action = action
    }
}

/// The leading navigation control of a ``StoreTopAppBar``: back or close.
///
/// - Note: A closed type — the design offers exactly these two. Section app bars (tab roots) pass
///   `nil` instead and hide the control.
public struct StoreTopAppBarNavigation {
    let icon: StoreIconImage
    let accessibilityLabel: String
    /// Direction-bearing glyphs mirror in right-to-left layouts; symmetric ones don't.
    let flipsForRightToLeft: Bool
    let action: () -> Void

    private init(icon: StoreIconImage, accessibilityLabel: String, flipsForRightToLeft: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.flipsForRightToLeft = flipsForRightToLeft
        self.action = action
    }

    /// Back — a chevron that navigates up the hierarchy.
    public static func back(action: @escaping () -> Void) -> StoreTopAppBarNavigation {
        StoreTopAppBarNavigation(icon: StoreIcon.AngleLeft.regular,
                                 accessibilityLabel: Localization.back,
                                 flipsForRightToLeft: true,
                                 action: action)
    }

    /// Close — an X that dismisses a modal flow.
    public static func close(action: @escaping () -> Void) -> StoreTopAppBarNavigation {
        StoreTopAppBarNavigation(icon: StoreIcon.Xmark.regular,
                                 accessibilityLabel: Localization.close,
                                 flipsForRightToLeft: false,
                                 action: action)
    }
}

private enum Localization {
    static let back = NSLocalizedString(
        "storeTopAppBar.navigation.back",
        value: "Back",
        comment: "VoiceOver label of the back control in a top app bar."
    )
    static let close = NSLocalizedString(
        "storeTopAppBar.navigation.close",
        value: "Close",
        comment: "VoiceOver label of the close control in a top app bar."
    )
}
