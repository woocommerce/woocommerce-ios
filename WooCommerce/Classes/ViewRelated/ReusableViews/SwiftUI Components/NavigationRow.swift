import SwiftUI

/// Renders a row with custom content inside and a disclosure indicator if selectable
///
struct NavigationRow<Content: View>: View {

    /// Enables disclosure indicator and action on tap
    ///
    let selectable: Bool

    /// Content to render inside
    ///
    let content: Content

    /// Action when the row is selected
    ///
    let action: () -> Void

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    init(selectable: Bool = true,
         @ViewBuilder content: () -> Content,
         action: @escaping () -> Void) {
        self.selectable = selectable
        self.content = content()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                content
                Spacer()
                DisclosureIndicator()
                    .renderedIf(selectable)
            }
            .padding()
            .padding(.horizontal, insets: safeAreaInsets)
            .frame(minHeight: Layout.minHeight)
        }
        .disabled(!selectable)
    }
}

private enum Layout {
    static let minHeight: CGFloat = 44
}

struct NavigationRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationRow(content: {
            Text("Title")
                .bodyStyle()
        }, action: {})
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Simple content")

        NavigationRow(content: {
            VStack(alignment: .leading) {
                Text("Title")
                    .bodyStyle()
                Text("Subtitle")
                    .footnoteStyle()
            }
        }, action: {})
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("VStack")

        NavigationRow(content: {
            Text("Title")
                .bodyStyle()
        }, action: {})
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewLayout(.fixed(width: 375, height: 120))
            .previewDisplayName("Dynamic Type: Large Font Size")
    }
}
