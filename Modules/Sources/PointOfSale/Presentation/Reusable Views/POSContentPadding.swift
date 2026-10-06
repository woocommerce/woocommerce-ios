import SwiftUI

private struct POSContentPaddingModifier: ViewModifier {
    let padding: EdgeInsets
    @State private var clearance = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: padding.top,
                                leading: max(0, padding.leading - clearance.leading),
                                bottom: padding.bottom,
                                trailing: max(0, padding.trailing - clearance.trailing)))
            .onGeometryChange(for: EdgeInsets.self) { geometry in
                var clearance = EdgeInsets()
                #if canImport(SwiftUI, _version: 8.0.85.27)
                if #available(iOS 27.1, *) {
                    for region in geometry.reservedRegions(kind: .division) where region.isActive {
                        let margins = POSContentPadding.clearance(size: geometry.size, frame: region.frame, margins: region.margins)
                        clearance.leading = max(clearance.leading, margins.leading)
                        clearance.trailing = max(clearance.trailing, margins.trailing)
                    }
                }
                #endif
                return clearance
            } action: { clearance = $0 }
    }
}

enum POSContentPadding {
    static func clearance(size: CGSize, frame: CGRect, margins: EdgeInsets) -> EdgeInsets {
        var clearance = EdgeInsets()
        if frame.maxX <= 0 {
            clearance.leading = max(0, margins.trailing + frame.maxX)
        }
        if frame.minX >= size.width {
            clearance.trailing = max(0, margins.leading - (frame.minX - size.width))
        }
        return clearance
    }
}

extension View {
    func posContentPadding(_ padding: EdgeInsets) -> some View {
        modifier(POSContentPaddingModifier(padding: padding))
    }

    /// Counts nearby fold clearance toward content spacing at the requested edges.
    func posContentPadding(_ edges: Edge.Set = .all, _ padding: CGFloat) -> some View {
        posContentPadding(EdgeInsets(top: edges.contains(.top) ? padding : 0,
                                    leading: edges.contains(.leading) ? padding : 0,
                                    bottom: edges.contains(.bottom) ? padding : 0,
                                    trailing: edges.contains(.trailing) ? padding : 0))
    }
}
