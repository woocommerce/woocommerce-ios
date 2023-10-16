import SwiftUI

/// A generic View that stacks two custom Views, `Label` and `Content`, vertically
/// Then arranges the `Content` Views  horizontally
///
///     LineDetailView(label: {
///         Text("Options")
///     }, content: {
///         Image(systemName: "star.fill")
///         Text("Favorited")
///         Image(systemName: "checkmark.circle.fill")
///     })
///
struct LineDetailView<Label: View, Content: View>: View {
    private let label: Label
    private let content: Content

    init(@ViewBuilder label: () -> Label, @ViewBuilder content: () -> Content) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            label
                .padding()
            HStack {
                content
            }
        }
    }
}
