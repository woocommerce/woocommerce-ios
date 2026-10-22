import SwiftUI

/// How a tab's content sits inside its block, resolved from whether it has an icon.
///
/// The design stacks the icon and a cap-trimmed label above a p6 bottom inset, with the icon flush
/// against the row's top edge (Android does the same). SwiftUI text isn't cap-trimmed: its line box
/// extends ~4 pt below the baseline, so a text-only tab sits at the bottom above a p5 inset, which
/// lands the baseline where the design's p6 does. An icon tab sits at the top with a p1 inset above
/// the icon and a p3 inset under the label, so the row stays at its design height at the default
/// text size and the label keeps clear of the indicator when the text grows.
struct StoreTabRowLayout: Equatable {
    let contentAlignment: Alignment
    let topInset: CGFloat
    let bottomInset: CGFloat

    init(hasIcon: Bool) {
        contentAlignment = hasIcon ? .top : .bottom
        topInset = hasIcon ? StorePadding.p1 : StorePadding.p0
        bottomInset = hasIcon ? StorePadding.p3 : StorePadding.p5
    }
}
