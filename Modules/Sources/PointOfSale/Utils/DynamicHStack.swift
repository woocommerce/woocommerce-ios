import SwiftUI

/// HStack that turns into VStack with large accessibility sizes
struct DynamicHStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat
    let content: () -> Content

    init(horizontalAlignment: HorizontalAlignment = .leading,
         verticalAlignment: VerticalAlignment = .center,
         spacing: CGFloat = 0,
         @ViewBuilder content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        dynamicLayout(content)
    }

    private var dynamicLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))
        } else {
            AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
        }
    }
}
