import SwiftUI

/// A contextual overlay that surfaces supporting information, anchored to a target element via a
/// directional arrow.
///
/// - Note: A passive visual (bubble + arrow); presenting and anchoring it over a target is the
///   caller's responsibility. It hugs its content — apply `.frame(maxWidth:)` to wrap long text.
public struct StoreTooltip: View {
    private let title: String
    private let message: String?
    private let arrow: StoreTooltipArrow

    public init(_ title: String,
                message: String? = nil,
                arrow: StoreTooltipArrow = .topCenter) {
        self.title = title
        self.message = message
        self.arrow = arrow
    }

    public var body: some View {
        bubble
            .padding(stripEdge, TooltipMetrics.arrowDepth)
            .overlay(alignment: overlayAlignment) {
                arrowView
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

    private var arrowView: some View {
        TooltipArrowShape(edge: arrow.edge)
            .fill(Color.storeInverseSurface)
            .frame(width: arrowWidth, height: arrowHeight)
            .padding(insetEdge, insetAmount)
    }
}

// MARK: - Layout derivation
private extension StoreTooltip {
    var isVerticalArrow: Bool {
        arrow.edge == .top || arrow.edge == .bottom
    }

    var arrowWidth: CGFloat {
        isVerticalArrow ? TooltipMetrics.arrowBase : TooltipMetrics.arrowDepth
    }

    var arrowHeight: CGFloat {
        isVerticalArrow ? TooltipMetrics.arrowDepth : TooltipMetrics.arrowBase
    }

    /// The bubble edge on which the arrow's protrusion is reserved.
    var stripEdge: Edge.Set {
        switch arrow.edge {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    /// Anchors the arrow to the correct edge and position; SwiftUI resolves the coordinates.
    var overlayAlignment: Alignment {
        switch arrow.edge {
        case .top: Alignment(horizontal: alongEdgeHorizontal, vertical: .top)
        case .bottom: Alignment(horizontal: alongEdgeHorizontal, vertical: .bottom)
        case .leading: Alignment(horizontal: .leading, vertical: alongEdgeVertical)
        case .trailing: Alignment(horizontal: .trailing, vertical: alongEdgeVertical)
        }
    }

    var alongEdgeHorizontal: HorizontalAlignment {
        switch arrow.alignment {
        case .start: .leading
        case .center: .center
        case .end: .trailing
        }
    }

    var alongEdgeVertical: VerticalAlignment {
        switch arrow.alignment {
        case .start: .top
        case .center: .center
        case .end: .bottom
        }
    }

    /// Insets the arrow from the corner for the start/end placements.
    var insetEdge: Edge.Set {
        switch (isVerticalArrow, arrow.alignment) {
        case (true, .start): .leading
        case (true, .end): .trailing
        case (false, .start): .top
        case (false, .end): .bottom
        default: []
        }
    }

    var insetAmount: CGFloat {
        arrow.alignment == .center ? 0 : TooltipMetrics.cornerInset
    }
}
