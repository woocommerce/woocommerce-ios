import SwiftUI

struct POSContentPaddingContext: Sendable {
    var bounds = CGRect.zero
    var regions: [(frame: CGRect, margins: EdgeInsets)] = []

    func clearance(for frame: CGRect, layoutDirection: LayoutDirection) -> EdgeInsets {
        var clearance = EdgeInsets()
        let x = layoutDirection == .rightToLeft ? bounds.maxX - frame.maxX : frame.minX - bounds.minX
        for region in regions {
            let localFrame = region.frame.offsetBy(dx: -x, dy: bounds.minY - frame.minY)
            let margins = POSContentPadding.clearance(size: frame.size, frame: localFrame, margins: region.margins)
            clearance.leading = max(clearance.leading, margins.leading)
            clearance.trailing = max(clearance.trailing, margins.trailing)
        }
        return clearance
    }
}

extension EnvironmentValues {
    @Entry var posContentPaddingContext = POSContentPaddingContext()
}

private struct POSContentPaddingModifier: ViewModifier {
    @Environment(\.posContentPaddingContext) private var context
    @Environment(\.layoutDirection) private var layoutDirection
    let padding: EdgeInsets
    @State private var clearance = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: padding.top,
                                leading: max(0, padding.leading - clearance.leading),
                                bottom: padding.bottom,
                                trailing: max(0, padding.trailing - clearance.trailing)))
            .onGeometryChange(for: EdgeInsets.self) { [context, layoutDirection] geometry in
                context.clearance(for: geometry.frame(in: .global), layoutDirection: layoutDirection)
            } action: { clearance = $0 }
    }
}

enum POSContentPadding {
    /// The frame includes margins. Credit the margin already between the division and this content edge.
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
    func posContentPadding(_ edges: Edge.Set, _ padding: CGFloat) -> some View {
        posContentPadding(EdgeInsets(top: edges.contains(.top) ? padding : 0,
                                    leading: edges.contains(.leading) ? padding : 0,
                                    bottom: edges.contains(.bottom) ? padding : 0,
                                    trailing: edges.contains(.trailing) ? padding : 0))
    }
}
