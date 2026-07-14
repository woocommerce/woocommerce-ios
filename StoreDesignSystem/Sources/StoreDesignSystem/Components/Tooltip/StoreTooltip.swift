import SwiftUI

/// A contextual overlay that surfaces supporting information, anchored to a target element via a
/// directional arrow. A passive visual — it is presented over an anchor with
/// `storeTooltip(isPresented:preferredPlacement:title:message:)`, which computes the arrow edge and
/// tip position.
struct StoreTooltip: View {
    let title: String
    let message: String?
    /// The bubble edge the arrow sits on.
    let arrowEdge: Edge
    /// The arrow tip's offset along that edge, from the bubble's leading/top corner.
    let arrowTip: CGFloat

    var body: some View {
        bubble
            .padding(Edge.Set(arrowEdge), TooltipMetrics.arrowDepth)
            .overlay(alignment: arrowCorner) {
                TooltipArrowShape(edge: arrowEdge)
                    .fill(Color.storeInverseSurface)
                    .frame(width: arrowWidth, height: arrowHeight)
                    .offset(arrowOffset)
            }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s4) {
            Text(title)
                .storeTextStyle(.bodyMedium.emphasized)
            if let message {
                Text(message)
                    .storeTextStyle(.bodyMedium)
            }
        }
        .foregroundStyle(Color.storeOnInverseSurface)
        .padding(StorePadding.p6)
        .background(Color.storeInverseSurface)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.large))
    }
}

// MARK: - Arrow positioning
private extension StoreTooltip {
    var isHorizontalEdge: Bool {
        arrowEdge == .top || arrowEdge == .bottom
    }

    var arrowWidth: CGFloat {
        isHorizontalEdge ? TooltipMetrics.arrowBase : TooltipMetrics.arrowDepth
    }

    var arrowHeight: CGFloat {
        isHorizontalEdge ? TooltipMetrics.arrowDepth : TooltipMetrics.arrowBase
    }

    /// The arrow is pinned to its edge's leading/top corner and slid along the edge by ``arrowOffset``.
    var arrowCorner: Alignment {
        switch arrowEdge {
        case .top: .topLeading
        case .bottom: .bottomLeading
        case .leading: .topLeading
        case .trailing: .topTrailing
        }
    }

    /// Moves the corner-pinned arrow so its tip lands ``arrowTip`` points along the edge (the base
    /// spans the arrow width, so shift by half of that to center the tip on the target).
    var arrowOffset: CGSize {
        let alongEdge = arrowTip - TooltipMetrics.arrowBase / 2
        return isHorizontalEdge ? CGSize(width: alongEdge, height: 0) : CGSize(width: 0, height: alongEdge)
    }
}
