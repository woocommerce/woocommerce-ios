import SwiftUI

/// View to collapse an HStack layout to a VStack if the content is larger than the available space.
///
struct CollapsibleHStack<Content: View>: View {
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: VerticalAlignment
    private let spacing: CGFloat?
    private let content: () -> Content

    init(horizontalAlignment: HorizontalAlignment = .center,
         verticalAlignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: verticalAlignment, spacing: spacing, content: content)
            VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
        }
    }
}
