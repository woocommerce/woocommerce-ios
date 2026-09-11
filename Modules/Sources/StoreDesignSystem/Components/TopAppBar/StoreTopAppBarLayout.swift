import SwiftUI

/// The horizontal text insets of a ``StoreTopAppBar`` for a given configuration.
///
/// The design positions the text against the bar's edge, the navigation control, or the
/// actions, depending on what's present; this keeps that arithmetic in one testable place.
struct StoreTopAppBarLayout: Equatable {
    let size: StoreTopAppBarSize
    let hasNavigation: Bool
    let actionCount: Int

    /// The bar's own leading inset before the navigation control.
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

    /// Space between leading-aligned text and the actions (or the bar's trailing edge).
    var textTrailingInset: CGFloat {
        switch size {
        case .small: StorePadding.p0
        case .medium: StorePadding.p5
        }
    }

    /// The symmetric inset of centered text: the wider of the two control clusters plus a gap, so
    /// the text stays centered on the bar without running under a control.
    var centeredTextInset: CGFloat {
        switch size {
        case .small:
            let navigationWidth = hasNavigation ? barLeadingInset + StoreSize.topAppBarControlSize : 0
            let actionsWidth = StorePadding.p2 + StoreSize.topAppBarControlSize * CGFloat(actionCount)
            return max(StorePadding.p7, max(navigationWidth, actionsWidth) + StoreSpacing.s2)
        case .medium:
            return textLeadingInset
        }
    }
}
