import SwiftUI

/// How a tab's content sits inside its block, resolved from whether it has an icon.
///
/// The design stacks the icon and a cap-trimmed label above a p6 bottom inset, with the icon flush
/// against the row's top edge (Android does the same). SwiftUI text isn't cap-trimmed, so a text-only
/// tab keeps the p6 inset and sits at the bottom, while an icon tab is centered with a p2 inset on
/// both sides: the row stays at its design height at the default text size and the icon and label
/// keep clear of the edges when the text grows.
struct StoreTabRowLayout: Equatable {
    let contentAlignment: Alignment
    let topInset: CGFloat
    let bottomInset: CGFloat

    init(hasIcon: Bool) {
        contentAlignment = hasIcon ? .center : .bottom
        topInset = hasIcon ? StorePadding.p2 : StorePadding.p0
        bottomInset = hasIcon ? StorePadding.p2 : StorePadding.p6
    }
}
