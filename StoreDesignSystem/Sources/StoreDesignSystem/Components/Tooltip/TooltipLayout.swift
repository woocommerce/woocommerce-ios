import SwiftUI

/// Pure geometry for presenting a ``StoreTooltip``: given where the anchor sits on screen, it
/// decides which side to open on, how wide the bubble may be, how far to offset it, and where the
/// arrow sits so it points at the anchor. Extracted from the view layer so this logic — which is
/// easy to get subtly wrong and hard to eyeball — can be unit-tested without SwiftUI.
struct TooltipLayout {
    /// The anchor's frame in the same space as `bounds` (global/screen).
    let anchorFrame: CGRect
    /// The area the bubble must stay within (the screen).
    let bounds: CGRect

    enum Constants {
        /// Nominal bubble height used to decide whether a top/bottom placement has vertical room.
        static let estimatedHeight: CGFloat = 150
        /// Bubble width bounds and the inset kept from the screen edges.
        static let maxBubbleWidth: CGFloat = 300
        static let minBubbleWidth: CGFloat = 80
        /// Kept small so a bubble anchored to a screen-edge element (e.g. a nav-bar button) can sit
        /// close enough to the edge for its arrow to reach the anchor.
        static let screenMargin: CGFloat = 8
        /// A small gap between the arrow tip and the anchor edge.
        static let anchorGap: CGFloat = 4
        /// The closest the arrow tip may sit to a bubble corner before its base would overlap the
        /// rounded corner.
        static let minArrowTipInset: CGFloat = StoreRadius.large + TooltipArrowShape.base / 2
    }

    /// The bubble edge the arrow renders on: a preferred placement is honored unless its side lacks
    /// room (then it flips); with no preference the bubble opens toward the roomier vertical side.
    func resolvedArrowEdge(preferred: Edge?, bubbleSize: CGSize = .zero) -> Edge {
        guard anchorFrame != .zero else {
            return preferred ?? .top
        }
        if let preferred {
            return shouldFlip(preferred, bubbleSize: bubbleSize) ? preferred.opposite : preferred
        }
        let roomBelow = bounds.maxY - anchorFrame.maxY
        let roomAbove = anchorFrame.minY - bounds.minY
        return roomBelow >= roomAbove ? .top : .bottom
    }

    /// A preferred placement is flipped when its side can't fit the bubble. The width adapts to the
    /// room on a leading/trailing side, so those only flip when truly cramped; a top/bottom bubble's
    /// height doesn't adapt, so it flips against the measured height (falling back to a nominal one
    /// before the first measurement) rather than assuming the bubble is short.
    func shouldFlip(_ arrowEdge: Edge, bubbleSize: CGSize = .zero) -> Bool {
        let requiredHeight = bubbleSize.height > 0 ? bubbleSize.height : Constants.estimatedHeight
        return switch arrowEdge {
        case .top: bounds.maxY - anchorFrame.maxY < requiredHeight
        case .bottom: anchorFrame.minY - bounds.minY < requiredHeight
        case .leading: bounds.maxX - anchorFrame.maxX - TooltipArrowShape.depth < Constants.minBubbleWidth
        case .trailing: anchorFrame.minX - bounds.minX - TooltipArrowShape.depth < Constants.minBubbleWidth
        }
    }

    /// The width the bubble may occupy before it would spill off screen: the full width for a
    /// top/bottom placement (the bubble slides along the edge as needed), or the room on the
    /// anchor's chosen side for a leading/trailing one.
    func availableBubbleWidth(for arrowEdge: Edge) -> CGFloat {
        let leftLimit = bounds.minX + Constants.screenMargin
        let rightLimit = bounds.maxX - Constants.screenMargin
        let room: CGFloat = switch arrowEdge {
        case .top, .bottom: rightLimit - leftLimit
        case .leading: rightLimit - anchorFrame.maxX - TooltipArrowShape.depth
        case .trailing: anchorFrame.minX - TooltipArrowShape.depth - leftLimit
        }
        return min(Constants.maxBubbleWidth, max(Constants.minBubbleWidth, room))
    }

    /// Offset from a bubble centered on the anchor: pushes it fully onto the arrow's side, then
    /// clamps it back within the screen margins on both axes. In the common case the bubble already
    /// fits and the clamp is a no-op; near a screen edge it shifts the bubble and the arrow slides
    /// to compensate.
    func bubbleOffset(for arrowEdge: Edge, bubbleSize: CGSize) -> CGSize {
        // The bubble frame already includes the arrow strip, so half the anchor plus half the bubble
        // puts the arrow tip on the anchor's edge; a small gap lifts it just clear.
        let mainOffset = { (anchorExtent: CGFloat, bubbleExtent: CGFloat) in
            anchorExtent / 2 + bubbleExtent / 2 + Constants.anchorGap
        }
        let raw: CGSize = switch arrowEdge {
        case .top: CGSize(width: 0, height: mainOffset(anchorFrame.height, bubbleSize.height))
        case .bottom: CGSize(width: 0, height: -mainOffset(anchorFrame.height, bubbleSize.height))
        case .leading: CGSize(width: mainOffset(anchorFrame.width, bubbleSize.width), height: 0)
        case .trailing: CGSize(width: -mainOffset(anchorFrame.width, bubbleSize.width), height: 0)
        }
        return clamped(raw, bubbleSize: bubbleSize)
    }

    /// Where the arrow tip sits along the bubble's edge, measured from the bubble's leading/top
    /// corner, so it points at the anchor's center: the middle when the bubble is centered on the
    /// anchor (the common case), sliding toward a corner — never closer than ``minArrowTipInset`` —
    /// when the on-screen clamp shifted the bubble.
    func arrowTipAlongEdge(for arrowEdge: Edge, bubbleSize: CGSize, bubbleOffset: CGSize) -> CGFloat {
        let isHorizontalEdge = arrowEdge == .top || arrowEdge == .bottom
        let length = isHorizontalEdge ? bubbleSize.width : bubbleSize.height
        let minInset = Constants.minArrowTipInset
        // Too small to inset from both ends — leave the arrow centered.
        guard length > 2 * minInset else { return length / 2 }
        // The bubble is centered on the anchor then shifted by the offset's cross component; undoing
        // that shift lands the tip back on the anchor's center.
        let crossShift = isHorizontalEdge ? bubbleOffset.width : bubbleOffset.height
        return min(max(length / 2 - crossShift, minInset), length - minInset)
    }

    /// Nudges the offset so the whole bubble stays within the margins on both axes.
    private func clamped(_ offset: CGSize, bubbleSize: CGSize) -> CGSize {
        guard bubbleSize != .zero else { return offset }
        func clampCenter(_ center: CGFloat, half: CGFloat, low: CGFloat, high: CGFloat) -> CGFloat {
            let minCenter = low + half
            let maxCenter = high - half
            // If the bubble is larger than the space, there is nothing to clamp to — leave it centered.
            guard minCenter <= maxCenter else { return center }
            return min(max(center, minCenter), maxCenter)
        }
        let clampedX = clampCenter(anchorFrame.midX + offset.width,
                                   half: bubbleSize.width / 2,
                                   low: bounds.minX + Constants.screenMargin,
                                   high: bounds.maxX - Constants.screenMargin)
        let clampedY = clampCenter(anchorFrame.midY + offset.height,
                                   half: bubbleSize.height / 2,
                                   low: bounds.minY + Constants.screenMargin,
                                   high: bounds.maxY - Constants.screenMargin)
        return CGSize(width: clampedX - anchorFrame.midX, height: clampedY - anchorFrame.midY)
    }
}
