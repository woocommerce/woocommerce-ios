import SwiftUI

struct FeedbackView: View {
    let title: String
    var backgroundColor: Color = .init(uiColor: .systemGray5)
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var vote: Vote?

    enum Vote: String, Equatable {
        case up
        case down
    }

    var body: some View {
        HStack {
            Text(title)
                .subheadlineStyle()
            Spacer()
            HStack(spacing: Layout.buttonSpacing) {
                Button {
                    onUpvote()
                    vote = .up
                } label: {
                    Image(systemName: vote == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .resizable()
                        .frame(width: Layout.iconSize * scale,
                               height: Layout.iconSize * scale)
                        .foregroundColor(vote == .up ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Button {
                    onDownvote()
                    vote = .down
                } label: {
                    Image(systemName: vote == .down ?  "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .resizable()
                        .frame(width: Layout.iconSize * scale,
                               height: Layout.iconSize * scale)
                        .foregroundColor(vote == .down ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.contentInsets)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .foregroundColor(backgroundColor)
        )
    }
}

private extension FeedbackView {
    enum Layout {
        static let contentInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let cornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 20
        static let buttonSpacing: CGFloat = 16
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(title: "Test", onUpvote: {}, onDownvote: {})
    }
}
