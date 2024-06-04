import SwiftUI

/// View for displaying a popover with a prompt to share feedback.
///
struct FeedbackBannerPopover: View {
    /// Whether the popover is presented.
    @Binding var isPresented: Bool

    /// Configuration for the banner.
    var config: Configuration

    /// Defines whether the feedback survey is presented.
    @State private var isSurveyPresented: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            HStack(alignment: .center) {
                Text(config.title)
                    .foregroundStyle(Color(.textInverted))
                    .font(.headline)

                Spacer()

                Button {
                    config.onCloseButtonTapped()
                    isPresented = false
                } label: {
                    Image(uiImage: .closeButton)
                        .resizable()
                        .frame(width: Layout.buttonSize, height: Layout.buttonSize)
                        .foregroundStyle(Color(.invertedSecondaryLabel))
                }
                .accessibilityIdentifier("feedback-banner-popover-close-button")
            }

            Text(config.message)
                .foregroundStyle(Color(.textInverted))

            Button {
                isSurveyPresented = true
                config.onSurveyButtonTapped()
            } label: {
                HStack {
                    Image(uiImage: .tooltipImage)
                    Text(config.buttonTitle)
                }
                .foregroundStyle(Color(.wooCommercePurple(.shade20)))
                .bold()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(.popoverBackground))
                .shadow(color: Color(.secondaryLabel), radius: Layout.shadowRadius, y: Layout.shadowYOffset)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .transition(.opacity.animation(.easeInOut))
        .sheet(isPresented: $isSurveyPresented) {
            Survey(source: config.feedbackType, onDismiss: {
                isPresented = false
            })
        }
        .renderedIf(isPresented)
    }

    struct Configuration {
        /// Banner title.
        let title: String

        /// Banner message.
        let message: String

        /// Title for button that opens the survey.
        let buttonTitle: String

        /// Feedback survey type.
        let feedbackType: SurveyViewController.Source

        /// Closure triggered when survey button is tapped.
        let onSurveyButtonTapped: () -> Void

        /// Closure triggered when close button is tapped.
        let onCloseButtonTapped: () -> Void
    }
}

private extension FeedbackBannerPopover {
    enum Layout {
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 2
        static let buttonSize: CGFloat = 16
    }
}

#Preview {
    FeedbackBannerPopover(isPresented: .constant(true), config: .init(title: "Take a survey!",
                                                                      message: "What do you think of the app?",
                                                                      buttonTitle: "Share your feedback",
                                                                      feedbackType: .inAppFeedback,
                                                                      onSurveyButtonTapped: {},
                                                                      onCloseButtonTapped: {}))
}
