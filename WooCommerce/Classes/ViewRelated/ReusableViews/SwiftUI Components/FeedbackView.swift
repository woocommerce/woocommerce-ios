import SwiftUI

struct FeedbackView: View {
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack {
            Text(Localization.feedbackQuestion)
                .subheadlineStyle()
            Spacer()
            HStack(spacing: Layout.buttonSpacing) {
                Button {
                    onUpvote()
                } label: {
                    Image(systemName: "hand.thumbsup")
                        .resizable()
                        .frame(width: Layout.iconSize * scale,
                               height: Layout.iconSize * scale)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    onDownvote()
                } label: {
                    Image(systemName: "hand.thumbsdown")
                        .resizable()
                        .frame(width: Layout.iconSize * scale,
                               height: Layout.iconSize * scale)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.contentInsets)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .foregroundColor(.init(uiColor: .systemGray5))
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
    enum Localization {
        static let feedbackQuestion = NSLocalizedString(
            "Is the generated description helpful?",
            comment: "Question to ask for feedback for the AI-generated content"
        )
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(onUpvote: {}, onDownvote: {})
    }
}
