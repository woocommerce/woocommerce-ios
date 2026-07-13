/// Where a ``StoreTooltip`` sits relative to the view it is anchored to, when presented with
/// `storeTooltip(isPresented:preferredPlacement:title:message:)`.
///
/// - Note: This describes the bubble's position relative to the anchor (the arrow always points back
///   at the anchor). It is the inverse of ``StoreTooltipArrow``, which names where the arrow sits on
///   the bubble — a `.below` placement uses a `.top` arrow, and so on. The presenter maps the chosen
///   placement to the matching arrow.
public struct StoreTooltipPlacement: Sendable {
    let arrow: StoreTooltipArrow

    private init(arrow: StoreTooltipArrow) {
        self.arrow = arrow
    }

    /// Below the anchor.
    public static let belowLeading = StoreTooltipPlacement(arrow: .topLeading)
    public static let belowCenter = StoreTooltipPlacement(arrow: .topCenter)
    public static let belowTrailing = StoreTooltipPlacement(arrow: .topTrailing)

    /// Above the anchor.
    public static let aboveLeading = StoreTooltipPlacement(arrow: .bottomLeading)
    public static let aboveCenter = StoreTooltipPlacement(arrow: .bottomCenter)
    public static let aboveTrailing = StoreTooltipPlacement(arrow: .bottomTrailing)

    /// On the anchor's leading side.
    public static let leadingTop = StoreTooltipPlacement(arrow: .trailingTop)
    public static let leadingCenter = StoreTooltipPlacement(arrow: .trailingCenter)
    public static let leadingBottom = StoreTooltipPlacement(arrow: .trailingBottom)

    /// On the anchor's trailing side.
    public static let trailingTop = StoreTooltipPlacement(arrow: .leadingTop)
    public static let trailingCenter = StoreTooltipPlacement(arrow: .leadingCenter)
    public static let trailingBottom = StoreTooltipPlacement(arrow: .leadingBottom)
}
