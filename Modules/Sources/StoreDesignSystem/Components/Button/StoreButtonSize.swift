import SwiftUI

/// The size of a ``StoreButton``.
///
/// - Note: A closed type — only the design sizes exist, each carrying its own typography, icon
///   size, padding, and corner radius, so there are no per-size branches at the call site or style.
public struct StoreButtonSize {
    let textStyle: StoreTextStyle
    let iconSize: StoreIconSize
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let cornerRadius: CGFloat

    private init(textStyle: StoreTextStyle,
                 iconSize: StoreIconSize,
                 horizontalPadding: CGFloat,
                 verticalPadding: CGFloat,
                 cornerRadius: CGFloat) {
        self.textStyle = textStyle
        self.iconSize = iconSize
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.cornerRadius = cornerRadius
    }

    public static let small = StoreButtonSize(
        textStyle: .labelMedium.emphasized,
        iconSize: .extraSmall,
        horizontalPadding: StorePadding.p5,
        verticalPadding: StorePadding.p3,
        cornerRadius: StoreRadius.large
    )

    public static let medium = StoreButtonSize(
        textStyle: .labelLarge.emphasized,
        iconSize: .medium,
        horizontalPadding: StorePadding.p5,
        verticalPadding: StorePadding.p6,
        cornerRadius: StoreRadius.extraLarge
    )
}
