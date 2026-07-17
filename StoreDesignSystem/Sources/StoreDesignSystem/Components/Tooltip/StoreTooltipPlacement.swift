import SwiftUI

/// Which side of its anchor a tooltip opens on, when presented with
/// `storeTooltip(isPresented:preferredPlacement:title:message:)`.
///
/// The placement names the side only: where the bubble and its arrow sit along that side is
/// computed by the presenter so the arrow points at the anchor and the bubble stays on screen.
public enum StoreTooltipPlacement: Sendable {
    case above
    case below
    case leading
    case trailing

    /// The bubble edge the arrow renders on — the inverse side, since the arrow points back at the
    /// anchor. Placement names follow the reading direction while the presenter's geometry is
    /// absolute (leading = left), so the horizontal placements swap in right-to-left layouts.
    func arrowEdge(in direction: LayoutDirection) -> Edge {
        switch self {
        case .above: .bottom
        case .below: .top
        case .leading: direction == .rightToLeft ? .leading : .trailing
        case .trailing: direction == .rightToLeft ? .trailing : .leading
        }
    }
}

extension Edge {
    /// The opposite edge, used to flip a placement whose side lacks room for the bubble.
    var opposite: Edge {
        switch self {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }
}
