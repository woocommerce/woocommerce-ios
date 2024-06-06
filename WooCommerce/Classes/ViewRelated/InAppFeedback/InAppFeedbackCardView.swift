import SwiftUI

struct InAppFeedbackCardView: View {
    private let viewModel: InAppFeedbackCardViewModel

    init(viewModel: InAppFeedbackCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Layout.padding) {
            Text(Localization.feedbackTitle)
                .headlineStyle()
                .multilineTextAlignment(.center)
                .padding(.top, Layout.padding)

            AdaptiveStack(spacing: Layout.padding) {
                Button(Localization.iLikeIt) {
                    viewModel.didTapILikeIt()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(Localization.couldBeBetter) {
                    viewModel.didTapCouldBeBetter()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Layout.padding)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.border), lineWidth: 1)
        )
    }
}

private extension InAppFeedbackCardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let feedbackTitle = NSLocalizedString(
            "inAppFeedbackCardView.feedbackTitle",
            value: "Are you enjoying the app?",
            comment: "The title used when asking the user for feedback for the app."
        )
        static let couldBeBetter = NSLocalizedString(
            "inAppFeedbackCardView.couldBeBetter",
            value: "Could be better",
            comment: "The title of the button for giving a negative feedback for the app."
        )
        static let iLikeIt = NSLocalizedString(
            "inAppFeedbackCardView.iLikeIt",
            value: "I like it",
            comment: "The title of the button for giving a positive feedback for the app."
        )
    }
}
