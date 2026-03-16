import SwiftUI

/// A custom presentation detent that shows ~1.5 cart item rows plus the summary bar.
/// Used for the collapsed cart sheet on phone POS.
struct POSCartPeekDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        // drag handle area + header + ~1.5 item rows + fade hint + summary bar
        let dragHandle: CGFloat = POSPadding.medium
        let header: CGFloat = 32
        let itemRows: CGFloat = 72 // ~1.5 rows
        let fadeHint: CGFloat = POSPadding.small
        let summaryBar: CGFloat = 52
        return dragHandle + header + itemRows + fadeHint + summaryBar
    }
}

extension PresentationDetent {
    static let cartPeek = Self.custom(POSCartPeekDetent.self)
}
