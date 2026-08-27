import SwiftUI

/// Shared policy for POS leading-edge back gestures.
struct POSEdgeSwipePolicy {
    static let activationWidth: CGFloat = 24
    static let minimumDragDistance: CGFloat = 8
    static let completionThreshold: CGFloat = 0.35

    let layoutDirection: LayoutDirection

    var edgeAlignment: Alignment {
        layoutDirection == .leftToRight ? .leading : .trailing
    }

    var direction: CGFloat {
        layoutDirection == .leftToRight ? 1 : -1
    }

    func normalized(_ horizontalTranslation: CGFloat) -> CGFloat {
        horizontalTranslation * direction
    }

    func clampedTranslation(_ horizontalTranslation: CGFloat, totalWidth: CGFloat) -> CGFloat {
        min(max(normalized(horizontalTranslation), 0), totalWidth)
    }

    func shouldComplete(translation: CGFloat, predictedEndTranslation: CGFloat, totalWidth: CGFloat) -> Bool {
        let current = normalized(translation)
        let projected = normalized(predictedEndTranslation)
        return max(projected, current) > totalWidth * Self.completionThreshold
    }
}

/// Recognizes a phone-style leading-edge swipe and invokes the screen's real back action.
///
/// This is intentionally an action gesture rather than an interactive transition. SwiftUI can
/// host a destination and its parent in different presentation containers, and a modifier on the
/// destination cannot reveal content owned by another container. Moving only the destination
/// exposes that container's empty background.
///
/// Use native interactive pop for genuine `NavigationStack` pushes and a container-owned
/// transition, such as `POSNavigationSplitView`, when both screens are available to render.
private struct POSEdgeSwipeBackAction: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.layoutDirection) private var layoutDirection

    let isEnabled: Bool
    let onBack: (() -> Void)?

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: policy.edgeAlignment) {
                content

                if isEnabled, horizontalSizeClass == .compact {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: POSEdgeSwipePolicy.activationWidth)
                        .frame(maxHeight: .infinity)
                        .gesture(backGesture(totalWidth: geometry.size.width))
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var policy: POSEdgeSwipePolicy {
        POSEdgeSwipePolicy(layoutDirection: layoutDirection)
    }

    private func backGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: POSEdgeSwipePolicy.minimumDragDistance)
            .onEnded { value in
                guard policy.shouldComplete(
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
