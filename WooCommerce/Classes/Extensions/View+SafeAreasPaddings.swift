import SwiftUI

/// Custom view modifer for adding paddings based on safe areas.
struct SafeAreasPaddings: ViewModifier {
    /// Safe area insets to for paddings.
    let insets: EdgeInsets

    /// Edges to add paddings to.
    let edges: Edge.Set

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
    /// Adds paddings to view when its super view has `ignoresSafeAreas` set.
    /// This is useful for keeping scroll views edge-to-edge.
    /// - Parameters:
    ///   - insets: Safe area insets to for paddings
    ///   - edges: Edges to add paddings to. Default to `.horizontal` as this is the most common value needed for edge-to-edge look of scroll views.
    /// - Returns: the modified `View` with paddings.
    func addSafeAreasPaddings(_ insets: EdgeInsets, edges: Edge.Set = .horizontal) -> some View {
        self.modifier(SafeAreasPaddings(insets: insets, edges: edges))
    }
}
