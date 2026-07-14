import CoreGraphics

/// Shared arrow geometry for the tooltip, used by both ``StoreTooltip`` and its presentation
/// modifier so the visual and its anchoring stay in sync.
enum TooltipMetrics {
    /// Triangle base width, along the edge.
    static let arrowBase: CGFloat = 22
    /// Triangle protrusion, perpendicular to the edge.
    static let arrowDepth: CGFloat = 10
    /// The closest the arrow tip may sit to a bubble corner before its base would overlap the
    /// rounded corner.
    static let minArrowTipInset: CGFloat = StoreRadius.large + arrowBase / 2
}
