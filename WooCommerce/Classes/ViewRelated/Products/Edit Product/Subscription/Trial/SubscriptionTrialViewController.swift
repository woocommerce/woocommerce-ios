import UIKit
import SwiftUI
import Kingfisher
import enum Yosemite.SubscriptionPeriod

// MARK: Hosting Controller

/// Hosting controller that wraps a `SubscriptionTrialView` view.
///
final class SubscriptionTrialViewController: UIHostingController<SubscriptionTrialView> {
    init(viewModel: SubscriptionTrialViewModel) {
        super.init(rootView: SubscriptionTrialView(viewModel: viewModel))
        title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders a list of components in a composite product
///
struct SubscriptionTrialView: View {

    /// View model that directs the view content.
    ///
    @StateObject var viewModel: SubscriptionTrialViewModel

    /// Scale of the view based on accessibility changes
    ///
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        Form {
            TitleAndTextFieldRow(title: Localization.duration,
                                 placeholder: "0",
                                 text: $viewModel.trialLength,
                                 keyboardType: .asciiCapableNumberPad,
                                 inputFormatter: IntegerInputFormatter(),
                                 minHeight: 0,
                                 horizontalPadding: 0)

            Picker(Localization.period, selection: $viewModel.trialPeriod) {
                ForEach(SubscriptionPeriod.allCases, id: \.self) {
                    Text($0.descriptionSingular)
                }
            }

            // Validation error
            ValidationErrorRow(errorMessage: viewModel.errorMessage,
                               minHeight: 0,
                               horizontalPadding: 0)
                .renderedIf(!viewModel.isInputValid)

            // Subtitle
            Text(Localization.freeTrialSubtitle)
                .foregroundColor(Color(.textSubtle))
                .subheadlineStyle()
                .renderedIf(viewModel.isInputValid)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.done) {
                    viewModel.didTapDone()
                }
                .disabled(!viewModel.isInputValid)
            }
        }
    }
}

private extension SubscriptionTrialView {
    enum Localization {
        static let duration = NSLocalizedString("subscriptionTrialView.duration",
                                                       value: "Duration",
                                                       comment: "Title for the free trial length row in add or edit subscription free trial screen.")
        static let period = NSLocalizedString("subscriptionTrialView.period",
                                                       value: "Period",
                                                       comment: "Title for the free trial period row in add or edit subscription free trial screen.")
        static let done = NSLocalizedString("subscriptionTrialView.done",
                                                       value: "Done",
                                            comment: "Title of the button to save subscription's free trial info.")
        static let freeTrialSubtitle = NSLocalizedString(
            "subscriptionTrialView.freeTrialSubtitle",
            value: "Free trial is an optional period of time to wait before charging the first recurring payment. " +
            "Any sign up fee will still be charged at the outset of the subscription.",
            comment: "Subtitle text to explain subscription free trial."
        )
    }
}

// MARK: Previews

struct SubscriptionTrialView_Previews: PreviewProvider {
    static let viewModel = SubscriptionTrialViewModel(subscription: .init(length: "1",
                                                                          period: .month,
                                                                          periodInterval: "1",
                                                                          price: "1",
                                                                          signUpFee: "1",
                                                                          trialLength: "12",
                                                                          trialPeriod: .day,
                                                                          oneTimeShipping: false,
                                                                          paymentSyncDate: "3",
                                                                          paymentSyncMonth: "01"),
                                                      completion: { _, _, _  in } )


    static var previews: some View {
        SubscriptionTrialView(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        SubscriptionTrialView(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        SubscriptionTrialView(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font")
    }
}
