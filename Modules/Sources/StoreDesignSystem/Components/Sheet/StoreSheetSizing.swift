import SwiftUI

/// How a sheet presented with `storeSheet(isPresented:sizing:onDismiss:content:)` sizes itself.
public enum StoreSheetSizing: Equatable, Sendable {
    /// The sheet hugs its content, up to the full-height sheet, and scrolls the content under a pinned
    /// grabber only when it is taller than that: the design's default, for option lists, short forms
    /// and confirmations. The content is offered unbounded height, so it must not scroll or expand itself.
    case fitContent
    /// The given system detents, for open-ended content that scrolls itself.
    case detents(Set<PresentationDetent>)
}

extension StoreSheetSizing {
    /// The detent the sheet opens at before its content has been measured.
    static let unmeasuredDetent: PresentationDetent = .medium

    /// The detents to present with, given the panel's height (`0` before its content is measured).
    func detents(panelHeight: CGFloat) -> Set<PresentationDetent> {
        switch self {
        case .fitContent:
            panelHeight > 0 ? [.height(panelHeight)] : [Self.unmeasuredDetent]
        case .detents(let detents):
            detents
        }
    }
}
