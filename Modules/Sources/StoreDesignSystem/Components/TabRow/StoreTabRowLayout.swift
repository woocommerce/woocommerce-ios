import SwiftUI

/// How a tab's content sits inside its block, resolved from whether it has an icon.
///
/// The design stacks the icon and a cap-trimmed label above a p6 bottom inset. SwiftUI text isn't
/// cap-trimmed, so a text-only tab keeps the p6 inset and sits at the bottom, while an icon tab
/// sits at the top with a p3 inset, so the taller stack fits the row height at the default text
/// size and the label keeps clear of the indicator at larger sizes.
struct StoreTabRowLayout: Equatable {
    let contentAlignment: Alignment
    let bottomInset: CGFloat

    init(hasIcon: Bool) {
        contentAlignment = hasIcon ? .top : .bottom
        bottomInset = hasIcon ? StorePadding.p3 : StorePadding.p6
    }
}
