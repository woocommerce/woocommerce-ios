import CoreGraphics

/// The inset treatment of a ``StoreDivider``.
///
/// - Note: A closed type holding the horizontal inset per variant. `full` spans edge to edge;
///   `inset` aligns the line with inset content.
public struct StoreDividerVariant {
    let horizontalInset: CGFloat

    private init(horizontalInset: CGFloat) {
        self.horizontalInset = horizontalInset
    }

    public static let full = StoreDividerVariant(horizontalInset: StorePadding.p0)

    public static let inset = StoreDividerVariant(horizontalInset: StorePadding.p7)
}
