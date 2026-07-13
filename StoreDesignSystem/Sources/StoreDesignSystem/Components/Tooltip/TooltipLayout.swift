import CoreGraphics

/// Pure geometry for presenting a ``StoreTooltip``: given where the anchor sits on screen, it decides
/// which arrow to use, how wide the bubble may be, and how far to offset it. Extracted from the view
/// layer so this logic — which is easy to get subtly wrong and hard to eyeball — can be unit-tested
/// without SwiftUI.
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
        static let screenMargin: CGFloat = 16
        /// A small gap between the arrow tip and the anchor edge.
        static let anchorGap: CGFloat = 4
    }

    /// The arrow to render: a preferred placement is honored unless its side lacks room (then it
    /// flips); with no preference the presenter picks a side from the anchor's position.
    func resolvedArrow(preferred: StoreTooltipArrow?, bubbleSize: CGSize = .zero) -> StoreTooltipArrow {
        guard anchorFrame != .zero else {
            return preferred ?? .topCenter
        }
        if let preferred {
            return shouldFlip(preferred, bubbleSize: bubbleSize) ? preferred.flipped : preferred
        }
        return autoArrow()
    }

    /// A preferred placement is flipped when its side can't fit the bubble. The width adapts to the
    /// room on a leading/trailing side, so those only flip when truly cramped; a top/bottom bubble's
    /// height doesn't adapt, so it flips against the measured height (falling back to a nominal one
    /// before the first measurement) rather than assuming the bubble is short.
    func shouldFlip(_ arrow: StoreTooltipArrow, bubbleSize: CGSize = .zero) -> Bool {
        let requiredHeight = bubbleSize.height > 0 ? bubbleSize.height : Constants.estimatedHeight
        return switch arrow.edge {
        case .top: bounds.maxY - anchorFrame.maxY < requiredHeight
        case .bottom: anchorFrame.minY - bounds.minY < requiredHeight
        case .leading: bounds.maxX - anchorFrame.maxX - TooltipMetrics.arrowDepth < Constants.minBubbleWidth
        case .trailing: anchorFrame.minX - bounds.minX - TooltipMetrics.arrowDepth < Constants.minBubbleWidth
        }
    }

    /// With no preference, open toward whichever vertical side has more room and align the arrow
    /// toward the anchor's horizontal third so the bubble stays on screen.
    func autoArrow() -> StoreTooltipArrow {
        let roomBelow = bounds.maxY - anchorFrame.maxY
        let roomAbove = anchorFrame.minY - bounds.minY
        let edge: StoreTooltipArrow.Edge = roomBelow >= roomAbove ? .top : .bottom
        return StoreTooltipArrow(edge: edge, alignment: horizontalAlignment())
    }

    func horizontalAlignment() -> StoreTooltipArrow.Alignment {
        let third = bounds.width / 3
        if anchorFrame.midX < bounds.minX + third {
            return .start
        }
        if anchorFrame.midX > bounds.maxX - third {
            return .end
        }
        return .center
    }

    /// The width the bubble may occupy before it would spill off screen. For a top/bottom arrow the
    /// bubble grows sideways from the arrow — which sits over the anchor's center — so the room
    /// depends on where along the edge the arrow is; for a leading/trailing arrow it is the space on
    /// the anchor's chosen side.
    func availableBubbleWidth(for arrow: StoreTooltipArrow) -> CGFloat {
        let leftLimit = bounds.minX + Constants.screenMargin
        let rightLimit = bounds.maxX - Constants.screenMargin
        let room: CGFloat
        switch arrow.edge {
        case .top, .bottom:
            switch arrow.alignment {
            case .center:
                room = 2 * min(anchorFrame.midX - leftLimit, rightLimit - anchorFrame.midX)
            case .start: // arrow near the bubble's leading edge; bubble extends toward the trailing side
                room = rightLimit - (anchorFrame.midX - TooltipMetrics.arrowTipInset)
            case .end: // arrow near the bubble's trailing edge; bubble extends toward the leading side
                room = (anchorFrame.midX + TooltipMetrics.arrowTipInset) - leftLimit
            }
        case .leading: // bubble sits on the anchor's trailing side
            room = rightLimit - anchorFrame.maxX - TooltipMetrics.arrowDepth
        case .trailing: // bubble sits on the anchor's leading side
            room = anchorFrame.minX - TooltipMetrics.arrowDepth - leftLimit
        }
        return min(Constants.maxBubbleWidth, max(Constants.minBubbleWidth, room))
    }

    /// Offset from a bubble centered on the anchor: pushes it fully onto the arrow's side (main axis)
    /// and slides it along the edge so the arrow tip meets the anchor's center (cross axis), then
    /// clamps the whole bubble back on screen.
    func bubbleOffset(for arrow: StoreTooltipArrow, bubbleSize: CGSize) -> CGSize {
        clamped(rawBubbleOffset(for: arrow, bubbleSize: bubbleSize), bubbleSize: bubbleSize)
    }

    /// The ideal offset, before clamping — arrow tip exactly on the anchor's edge center.
    func rawBubbleOffset(for arrow: StoreTooltipArrow, bubbleSize: CGSize) -> CGSize {
        // The bubble frame already includes the arrow strip, so half the anchor plus half the bubble
        // puts the arrow tip on the anchor's edge; a small gap lifts it just clear.
        let mainOffset = { (anchorExtent: CGFloat, bubbleExtent: CGFloat) in
            anchorExtent / 2 + bubbleExtent / 2 + Constants.anchorGap
        }
        switch arrow.edge {
        case .top:
            return CGSize(width: crossShift(along: bubbleSize.width, alignment: arrow.alignment),
                          height: mainOffset(anchorFrame.height, bubbleSize.height))
        case .bottom:
            return CGSize(width: crossShift(along: bubbleSize.width, alignment: arrow.alignment),
                          height: -mainOffset(anchorFrame.height, bubbleSize.height))
        case .leading:
            return CGSize(width: mainOffset(anchorFrame.width, bubbleSize.width),
                          height: crossShift(along: bubbleSize.height, alignment: arrow.alignment))
        case .trailing:
            return CGSize(width: -mainOffset(anchorFrame.width, bubbleSize.width),
                          height: crossShift(along: bubbleSize.height, alignment: arrow.alignment))
        }
    }

    /// Shift along the edge so a start/end arrow still points at the anchor's center.
    func crossShift(along length: CGFloat, alignment: StoreTooltipArrow.Alignment) -> CGFloat {
        switch alignment {
        case .center: 0
        case .start: length / 2 - TooltipMetrics.arrowTipInset
        case .end: -(length / 2 - TooltipMetrics.arrowTipInset)
        }
    }

    /// Nudges the offset so the whole bubble stays within the margins on both axes. In the common
    /// case the bubble already fits and this is a no-op; only when the anchor is close to an edge
    /// does it kick in, trading a small arrow-to-anchor drift for keeping the bubble on screen.
    func clamped(_ offset: CGSize, bubbleSize: CGSize) -> CGSize {
        guard bubbleSize != .zero else { return offset }
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

    private func clampCenter(_ center: CGFloat, half: CGFloat, low: CGFloat, high: CGFloat) -> CGFloat {
        let minCenter = low + half
        let maxCenter = high - half
        // If the bubble is larger than the space, there is nothing to clamp to — leave it centered.
        guard minCenter <= maxCenter else { return center }
        return min(max(center, minCenter), maxCenter)
    }
}
