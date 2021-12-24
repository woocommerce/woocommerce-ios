import SwiftUI

/// Custom view modifer for adding paddings based on given edge insets.
struct InsetPaddings: ViewModifier {
    /// Edges to add paddings to.
    let edges: Edge.Set

    /// Insets for paddings.
    let insets: EdgeInsets

    func body(content: Content) -> some View {
        switch edges {
        case .horizontal:
            content
                .padding(.leading, insets.leading)
                .padding(.trailing, insets.trailing)
        case .vertical:
            content
                .padding(.top, insets.top)
                .padding(.bottom, insets.bottom)
        case .leading:
            content.padding(.leading, insets.leading)
        case .trailing:
            content.padding(.trailing, insets.trailing)
        case .top:
            content.padding(.top, insets.top)
        case .bottom:
            content.padding(.bottom, insets.bottom)
        default:
            content.padding(insets)
        }
    }
}

extension View {
    /// Adds paddings to view with given edge insets
    /// - Parameters:
    ///   - edges: Edges to add paddings to. Default to `.all`
    ///   - insets: Safe area insets to for paddings
    /// - Returns: the modified `View` with paddings.
    func padding(_ edges: Edge.Set = .all, insets: EdgeInsets) -> some View {
        self.modifier(InsetPaddings(edges: edges, insets: insets))
    }
}
