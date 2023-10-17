import SwiftUI


/// View to display a single text with a bullet point preceding it.
///
struct BulletPointView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Layout.bulletPointStackSpacing) {
            Image(systemName: "circle.fill")
                .font(.system(size: Layout.bulletPointFontSize * scale))
                .offset(y: Layout.bulletPointVerticalOffset * scale)
            Text(text)
                .bodyStyle()
                .padding(.leading, Layout.textLeadingSpacing * scale)
        }
        .padding(Layout.bulletPointPadding * scale)
    }
}

private enum Layout {
    static let bulletPointPadding: EdgeInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 16)
    static let bulletPointStackSpacing: CGFloat = 4
    static let bulletPointFontSize: CGFloat = 4
    static let bulletPointVerticalOffset: CGFloat = 8
    static let textLeadingSpacing: CGFloat = 4
 }

struct BulletPointView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 14) {
            BulletPointView(text: "An example text on the bullet point")
            BulletPointView(
                text: "Another example of a really long text so we can see the bullet behavior for two and more lines"
            )

        }
    }
}
