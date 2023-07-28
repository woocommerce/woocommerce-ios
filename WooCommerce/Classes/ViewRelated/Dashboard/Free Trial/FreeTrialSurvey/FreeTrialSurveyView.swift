import SwiftUI

final class FreeTrialSurveyHostingController: UIHostingController<FreeTrialSurveyView> {
    init(viewModel: FreeTrialSurveyViewModel) {
        super.init(rootView: FreeTrialSurveyView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// View that presents a list of answers for Free trial survey
///
struct FreeTrialSurveyView: View {
    @ObservedObject private var viewModel: FreeTrialSurveyViewModel
    @FocusState private var isOtherReasonsFocused: Bool

    init(viewModel: FreeTrialSurveyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(Localization.title)
                    .fontWeight(.bold)
                    .titleStyle()

                VStack() {
                    ForEach(viewModel.answers, id: \.self) { answer in
                        if answer == .otherReasons {
                            TextField(answer.text, text: $viewModel.otherReasonSpecified, onEditingChanged: { focus in
                                if focus {
                                    viewModel.selectAnswer(.otherReasons)
                                }
                            })
                            .font(.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle(focused: isOtherReasonsFocused))
                            .focused($isOtherReasonsFocused)
                        } else {
                            Button(action: {
                                isOtherReasonsFocused = false
                                viewModel.selectAnswer(answer)
                            }, label: {
                                HStack {
                                    Text(answer.text)
                                    Spacer()
                                }
                            })
                            .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedAnswer == answer,
                                                                        labelFont: .body))
                        }
                    }
                }
            }
            .padding(Layout.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Layout.ctaPadding) {
                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.separator))

                Button(Localization.sendFeedback) {
                    viewModel.submitFeedback()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.ctaPadding)
                .disabled(!viewModel.feedbackSelected)
            }
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) {
                    viewModel.onClose()
                }
                .buttonStyle(TextButtonStyle())
            }
        }
    }
}

private extension FreeTrialSurveyView {
    enum Layout {
        static let dividerHeight: CGFloat = 1
        static let contentPadding: EdgeInsets = .init(top: 40, leading: 16, bottom: 16, trailing: 16)
        static let ctaPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Help us understand your subscription decisions. Your feedback matters.",
            comment: "Title in Free trail survey screen."
        )

        static let sendFeedback = NSLocalizedString(
            "Send Feedback",
            comment: "CTA button title which sends survey feedback."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the survey screen."
        )
    }
}

struct FreeTrialSurveyView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                FreeTrialSurveyView(viewModel: .init(source: .freeTrialSurvey24hAfterFreeTrialSubscribed, onClose: {}))
            }
        } else {
            FreeTrialSurveyView(viewModel: .init(source: .freeTrialSurvey24hAfterFreeTrialSubscribed, onClose: {}))
        }
    }
}
