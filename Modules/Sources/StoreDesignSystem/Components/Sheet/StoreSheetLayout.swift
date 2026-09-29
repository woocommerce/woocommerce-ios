import CoreGraphics

/// The layout rules of a ``StoreSheet``, as pure functions.
enum StoreSheetLayout {
    /// The strip the design reserves for the grabber above the content.
    static let grabberStripHeight: CGFloat = StorePadding.p5

    /// The design's `p5` minimum under the content; the system's bottom inset counts toward it.
    static func bottomInset(safeAreaInset: CGFloat) -> CGFloat {
        max(0, StorePadding.p5 - safeAreaInset)
    }

    /// The panel height for a `.height` detent, which excludes the system's bottom inset.
    static func panelHeight(contentHeight: CGFloat, safeAreaInset: CGFloat) -> CGFloat {
        grabberStripHeight + contentHeight + bottomInset(safeAreaInset: safeAreaInset)
    }
}
