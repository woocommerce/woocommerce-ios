import SwiftUI

/// An HStack layout that can be collapsed to a VStack when the content is too wide for the screen.
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
        ViewThatFits {
            HStack(alignment: verticalAlignment, spacing: spacing, content: content)
            VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
        }
    }
}
