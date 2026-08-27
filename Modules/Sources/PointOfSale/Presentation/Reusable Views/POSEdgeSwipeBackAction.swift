import SwiftUI

/// Shared policy for POS leading-edge back gestures.
struct POSEdgeSwipePolicy {
    /// How far in from the leading edge a drag may start and still count as a back swipe.
    ///
    /// iOS 26 dropped the edge requirement for its own back gesture — a swipe can begin anywhere.
    /// POS cannot follow that yet: this is a `simultaneousGesture`, which recognises alongside
    /// whatever else claims the touch and has no way to yield to a horizontal scroll view the way
    /// UIKit's recognizer does. An unrestricted swipe would both scroll and navigate on the header
    /// scroller (`POSPageHeaderView`) and the search-history chips (`POSPreSearchView`), which sit
    /// on the very screens this is enabled for. Matching iOS 26 properly needs a UIKit gesture that
    /// can `require(toFail:)` those recognizers.
    ///
    /// A touch-target's width rather than the old hairline, so the region is reachable without
    /// reaching so far in that the scrollers become hard to use.
    static let activationWidth: CGFloat = 44
    static let minimumDragDistance: CGFloat = 8
    static let completionThreshold: CGFloat = 0.35
    /// Used when the container has not reported a width yet. Without it the threshold would be
    /// zero, and a strict comparison against zero never completes however far the merchant swipes.
    static let fallbackCompletionDistance: CGFloat = 60
    /// How far the outgoing screen travels, as a fraction of the incoming screen's travel. UIKit
    /// moves the screen being left by roughly a third of the width, so it drifts under the arriving
    /// screen rather than sliding away with it.
    static let outgoingParallaxFraction: CGFloat = 0.3

    let layoutDirection: LayoutDirection

    /// `1` when a back swipe travels in the positive x direction, `-1` when it travels the other way.
    var direction: CGFloat {
        layoutDirection == .rightToLeft ? -1 : 1
    }

    /// Restates a horizontal translation as distance travelled *towards back*, whichever way that is.
    func normalized(_ horizontalTranslation: CGFloat) -> CGFloat {
        horizontalTranslation * direction
    }

    func clampedTranslation(_ horizontalTranslation: CGFloat, totalWidth: CGFloat) -> CGFloat {
        min(max(normalized(horizontalTranslation), 0), totalWidth)
    }

    func startsAtLeadingEdge(_ xPosition: CGFloat, totalWidth: CGFloat) -> Bool {
        layoutDirection == .rightToLeft
            ? xPosition >= totalWidth - Self.activationWidth
            : xPosition <= Self.activationWidth
    }

    /// Rejects a drag that is mostly vertical, so a scroll that begins near the edge and wanders
    /// sideways does not read as a back swipe.
    func isPredominantlyHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
    }

    func shouldComplete(translation: CGFloat, predictedEndTranslation: CGFloat, totalWidth: CGFloat) -> Bool {
        let current = normalized(translation)
        let projected = normalized(predictedEndTranslation)
        return max(projected, current) > completionDistance(totalWidth: totalWidth)
    }

    func completionDistance(totalWidth: CGFloat) -> CGFloat {
        totalWidth > 0 ? totalWidth * Self.completionThreshold : Self.fallbackCompletionDistance
    }

    // MARK: - Container-owned transition

    /// How far the incoming screen has travelled: `1` when it fully covers the outgoing screen,
    /// `0` when the outgoing screen is fully back.
    func incomingProgress(dragTranslation: CGFloat, totalWidth: CGFloat) -> CGFloat {
        guard totalWidth > 0 else { return 1 }
        return 1 - min(max(dragTranslation / totalWidth, 0), 1)
    }

    /// Moves a container holding both screens side by side, so the incoming one arrives from the
    /// trailing edge and covers the full width.
    func incomingOffset(progress: CGFloat, totalWidth: CGFloat) -> CGFloat {
        -progress * totalWidth * direction
    }

    /// Cancels most of the container's travel for the outgoing screen, leaving it the parallax
    /// fraction. Without this the two screens move as one sheet, which reads as the outgoing screen
    /// being dragged in from the side rather than revealed underneath.
    func outgoingParallaxOffset(progress: CGFloat, totalWidth: CGFloat) -> CGFloat {
        progress * totalWidth * (1 - Self.outgoingParallaxFraction) * direction
    }
}

/// Recognizes a phone-style leading-edge swipe and invokes the screen's real back action.
///
/// This is intentionally an action gesture rather than an interactive transition. SwiftUI can
/// host a destination and its parent in different presentation containers, and a modifier on the
/// destination cannot reveal content owned by another container. Moving only the destination
/// exposes that container's empty background.
///
/// Native interactive pop is not an alternative: POS hides the navigation bar on every screen,
/// which switches off UIKit's `interactivePopGestureRecognizer`. Where one container owns both
/// screens — as `POSNavigationSplitView` does — prefer its transition, which does track the finger.
///
/// The gesture attaches to the content rather than to an overlay strip. An overlay that is
/// hit-testable enough to receive a drag also becomes the hit target for taps, which would kill
/// every tap along the leading edge; `simultaneousGesture` recognizes alongside the content's own
/// gestures instead of competing with them. Attaching to the content also keeps the modifier
/// layout-neutral, which matters because several callers apply it to intrinsically sized cards.
private struct POSEdgeSwipeBackAction: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var totalWidth: CGFloat = 0

    let isEnabled: Bool
    let onBack: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { totalWidth = $0 }
            .simultaneousGesture(backGesture, isEnabled: isActive)
    }

    private var isActive: Bool {
        isEnabled && horizontalSizeClass == .compact
    }

    private var policy: POSEdgeSwipePolicy {
        POSEdgeSwipePolicy(layoutDirection: layoutDirection)
    }

    private var backGesture: some Gesture {
        DragGesture(minimumDistance: POSEdgeSwipePolicy.minimumDragDistance)
            .onEnded { value in
                guard policy.startsAtLeadingEdge(value.startLocation.x, totalWidth: totalWidth),
                      policy.isPredominantlyHorizontal(value.translation),
                      policy.shouldComplete(
                        translation: value.translation.width,
                        predictedEndTranslation: value.predictedEndTranslation.width,
                        totalWidth: totalWidth
                      ) else {
                    return
                }

                if let onBack {
                    onBack()
                } else {
                    dismiss()
                }
            }
    }
}

extension View {
    func posEdgeSwipeBackAction(isEnabled: Bool = true, onBack: (() -> Void)? = nil) -> some View {
        modifier(POSEdgeSwipeBackAction(isEnabled: isEnabled, onBack: onBack))
    }
}
