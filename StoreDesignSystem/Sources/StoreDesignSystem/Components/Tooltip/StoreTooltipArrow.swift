import SwiftUI

/// The arrow placement of a ``StoreTooltip`` — which edge the arrow sits on and where it points
/// along that edge.
///
/// - Note: A closed type holding an (edge, alignment) pair that ``StoreTooltip`` reads directly to
///   position the arrow; only the twelve design placements exist as presets.
public struct StoreTooltipArrow: Sendable {
    enum Edge {
        case top, bottom, leading, trailing
    }

    /// Position along the arrow's edge — `start`/`end` are leading/trailing on the top and bottom
    /// edges, and top/bottom on the leading and trailing edges.
    enum Alignment {
        case start, center, end
    }

    let edge: Edge
    let alignment: Alignment

    init(edge: Edge, alignment: Alignment) {
        self.edge = edge
        self.alignment = alignment
    }

    public static let topLeading = StoreTooltipArrow(edge: .top, alignment: .start)
    public static let topCenter = StoreTooltipArrow(edge: .top, alignment: .center)
    public static let topTrailing = StoreTooltipArrow(edge: .top, alignment: .end)

    public static let bottomLeading = StoreTooltipArrow(edge: .bottom, alignment: .start)
    public static let bottomCenter = StoreTooltipArrow(edge: .bottom, alignment: .center)
    public static let bottomTrailing = StoreTooltipArrow(edge: .bottom, alignment: .end)

    public static let leadingTop = StoreTooltipArrow(edge: .leading, alignment: .start)
    public static let leadingCenter = StoreTooltipArrow(edge: .leading, alignment: .center)
    public static let leadingBottom = StoreTooltipArrow(edge: .leading, alignment: .end)

    public static let trailingTop = StoreTooltipArrow(edge: .trailing, alignment: .start)
    public static let trailingCenter = StoreTooltipArrow(edge: .trailing, alignment: .center)
    public static let trailingBottom = StoreTooltipArrow(edge: .trailing, alignment: .end)

    /// The same placement on the opposite edge, keeping its position along that edge.
    var flipped: StoreTooltipArrow {
        let opposite: Edge = switch edge {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
        return StoreTooltipArrow(edge: opposite, alignment: alignment)
    }
}
