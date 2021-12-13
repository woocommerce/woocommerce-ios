import SwiftUI

/// Wraps a VStack inside a ScrollView, ensuring the content expands to fill the available space
///
struct ScrollableVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: alignment, spacing: spacing) {
                    content
                }
                .padding(24)
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
            }
        }
    }
}

struct ScrollableVStack_Previews: PreviewProvider {
    static var previews: some View {
        ScrollableVStack(spacing: 20) {
            Spacer()
            Text("A title")
                .font(.largeTitle)
            Text("""
                Lorem ipsum dolor sit amet, consectetur adipiscing
                elit, sed do eiusmod tempor incididunt ut labore et
                dolore magna aliqua. Ut enim ad minim veniam, quis
                nostrud exercitation ullamco laboris nisi ut aliquip
                ex ea commodo consequat. Duis aute irure dolor in
                reprehenderit in voluptate velit esse cillum dolore eu
                fugiat nulla pariatur. Excepteur sint occaecat
                cupidatat non proident, sunt in culpa qui officia
                deserunt mollit anim id est laborum.
                """)
            Spacer()
            Text("Footer")
                .font(.footnote)
        }
    }
}
