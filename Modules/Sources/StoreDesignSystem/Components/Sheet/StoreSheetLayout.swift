import CoreGraphics

/// The layout rules of a ``StoreSheet``, kept as pure functions so they can be tested.
enum StoreSheetLayout {
    /// The padding under the content. The design keeps `p5` between the content and the bottom of
    /// the sheet as a minimum: the system's own bottom inset (the home indicator area) counts toward
    /// it, so the padding only tops it up where that inset is smaller.
    static func bottomInset(safeAreaInset: CGFloat) -> CGFloat {
        max(0, StorePadding.p5 - safeAreaInset)
    }

    /// The height of a panel whose content measures `contentHeight`: the grabber strip, the content
    /// and the bottom inset. Excludes the system's own bottom inset, as a `.height` detent does.
    static func panelHeight(contentHeight: CGFloat, safeAreaInset: CGFloat) -> CGFloat {
        StoreSize.sheetGrabberAreaHeight + contentHeight + bottomInset(safeAreaInset: safeAreaInset)
    }
}
