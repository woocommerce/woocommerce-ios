import SwiftUI

/// The horizontal text insets of a ``StoreTopAppBar`` for a given configuration.
///
/// The design positions the text against the bar's edge, the navigation control, or the
/// actions, depending on what's present; this keeps that arithmetic in one testable place.
struct StoreTopAppBarLayout: Equatable {
    let size: StoreTopAppBarSize
    let hasNavigation: Bool
    let actionCount: Int

    /// The bar's own leading inset before the navigation control. The trailing inset before the
    /// bar's edge is always `p2`.
    var barLeadingInset: CGFloat {
        switch size {
        case .small: hasNavigation ? StorePadding.p2 : StorePadding.p0
        case .medium: StorePadding.p2
        }
    }

    /// Space between the navigation control (or the bar's leading edge) and leading-aligned text.
    var textLeadingInset: CGFloat {
        switch (size, hasNavigation) {
        case (.small, true): StoreSpacing.s2
        case (.medium, true): StorePadding.p5
        case (_, false): StorePadding.p7
        }
    }

    /// Space between leading-aligned text and the actions (or the bar's trailing edge). The small
    /// bar mirrors its leading gap after a navigation control and lets the text meet the actions
    /// when there is none, as the design does.
    var textTrailingInset: CGFloat {
        switch (size, hasNavigation) {
        case (.small, true): StoreSpacing.s2
        case (.small, false): StorePadding.p0
        case (.medium, _): StorePadding.p5
        }
    }

    /// Extra space before / after centered text that evens out the two control clusters, so the
    /// text centers on the bar rather than on the gap between the controls. At most one side is
    /// non-zero; the bar lets it shrink before the text truncates.
    var leadingCenteringBalance: CGFloat {
        max(0, trailingControlsWidth - leadingControlsWidth)
    }

    var trailingCenteringBalance: CGFloat {
        max(0, leadingControlsWidth - trailingControlsWidth)
    }

    /// The gap centered text keeps from the controls, or the bar's content inset when there are none.
    var centeredTextGap: CGFloat {
        hasNavigation || actionCount > 0 ? StoreSpacing.s2 : StorePadding.p7
    }

    /// The bar's leading inset plus the navigation control, measured from the bar's leading edge.
    private var leadingControlsWidth: CGFloat {
        barLeadingInset + (hasNavigation ? StoreSize.topAppBarControlSize : 0)
    }

    /// The actions plus the bar's trailing inset, measured from the bar's trailing edge.
    private var trailingControlsWidth: CGFloat {
        StorePadding.p2 + StoreSize.topAppBarControlSize * CGFloat(actionCount)
    }
}
