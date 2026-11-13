import SwiftUI

/// How a tab's content sits inside its block, resolved from whether it has an icon.
///
/// An icon tab sits at the top with a p1 inset above the icon and a p3 inset under the label, so the
/// row stays at its design height at the default text size and the label keeps clear of the
/// indicator when the text grows. A text-only tab is centred in the row with a p3 inset on both sides
/// (review decision; the design and Android bottom-align it above a p6 inset).
struct StoreTabRowLayout: Equatable {
    let contentAlignment: Alignment
    let topInset: CGFloat
    let bottomInset: CGFloat

    init(hasIcon: Bool) {
        contentAlignment = hasIcon ? .top : .center
        topInset = hasIcon ? StorePadding.p1 : StorePadding.p3
        bottomInset = StorePadding.p3
    }
}
