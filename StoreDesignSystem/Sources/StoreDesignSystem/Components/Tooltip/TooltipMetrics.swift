import CoreGraphics

/// Shared arrow geometry for the tooltip, used by both ``StoreTooltip`` and its presentation
/// modifier so the visual and its anchoring stay in sync.
enum TooltipMetrics {
    /// Triangle base width, along the edge.
    static let arrowBase: CGFloat = 22
    /// Triangle protrusion, perpendicular to the edge.
    static let arrowDepth: CGFloat = 10
    /// Distance from the bubble corner to the nearest base corner for start/end placements.
    static let cornerInset: CGFloat = 20
    /// Distance from the near edge to the arrow tip for start/end placements.
    static let arrowTipInset: CGFloat = cornerInset + arrowBase / 2
}
