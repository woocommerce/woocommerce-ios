import SwiftUI

/// How a sheet presented with `storeSheet(isPresented:sizing:onDismiss:content:)` sizes itself.
public enum StoreSheetSizing: Equatable, Sendable {
    /// The sheet hugs its content (the design's default) and scrolls it only when taller than the largest
    /// sheet. The content is offered unbounded height, so it must not scroll or expand itself.
    /// In regular width (iPad) the form sheet is fitted to the content's height the same way.
    case fitContent
    /// The given system detents. The content is not wrapped in a scroll view, so it must scroll itself
    /// (or be short enough for the smallest detent at every text size). In regular width (iPad) the
    /// system form sheet decides how, or whether, the detents apply.
    case detents(Set<PresentationDetent>)
}

extension StoreSheetSizing {
    /// The detent the sheet opens at before its content has been measured.
    static let unmeasuredDetent: PresentationDetent = .medium

    /// The detents for the panel's height; `0` (unmeasured) opens at the placeholder detent.
    func detents(panelHeight: CGFloat) -> Set<PresentationDetent> {
        switch self {
        case .fitContent:
            panelHeight > 0 ? [.height(panelHeight)] : [Self.unmeasuredDetent]
        case .detents(let detents):
            detents
        }
    }
}
