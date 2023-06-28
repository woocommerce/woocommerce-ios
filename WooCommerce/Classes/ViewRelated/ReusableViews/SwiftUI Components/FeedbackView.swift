import SwiftUI

struct FeedbackView: View {
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    var body: some View {
        HStack {
            Text(Localization.feedbackQuestion)
                .secondaryBodyStyle()
            Spacer()
            Button {
                onUpvote()
            } label: {
                Image(systemName: "hand.thumbsup")
                    .secondaryBodyStyle()
            }
            .buttonStyle(.plain)
            Button {
                onDownvote()
            } label: {
                Image(systemName: "hand.thumbsdown")
                    .secondaryBodyStyle()
            }
            .buttonStyle(.plain)
        }
        .padding(Layout.contentInsets)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .foregroundColor(.init(uiColor: .secondarySystemFill))
        )
    }
}

private extension FeedbackView {
    enum Layout {
        static let contentInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let cornerRadius: CGFloat = 8
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
