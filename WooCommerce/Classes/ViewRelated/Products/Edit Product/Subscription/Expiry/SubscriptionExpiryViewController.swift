import Foundation
import UIKit
import SwiftUI
import enum Yosemite.SubscriptionPeriod

// MARK: Hosting Controller

/// Hosting controller that wraps a `SubscriptionExpiryView` view.
///
final class SubscriptionExpiryViewController: UIHostingController<SubscriptionExpiryView> {
    init(viewModel: SubscriptionExpiryViewModel) {
        super.init(rootView: SubscriptionExpiryView(viewModel: viewModel))
        title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders a list of components in a composite product
///
struct SubscriptionExpiryView: View {

    /// View model that directs the view content.
    ///
    @StateObject var viewModel: SubscriptionExpiryViewModel

    /// Scale of the view based on accessibility changes
    ///
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var showPicker = false

    var body: some View {
        Form {
            Button(action: {
                showPicker.toggle()
            }, label: {
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(Localization.expireAfter)
                        .bodyStyle()
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text(viewModel.selectedLength.title)
                        .foregroundColor(Color(.accent))
                        .bodyStyle()
                        .multilineTextAlignment(.trailing)
                }
            })

            if showPicker {
                // Picker to select expiry
                Picker(Localization.expireAfter, selection: $viewModel.selectedLength) {
                    ForEach(viewModel.lengthOptions, id: \.self) {
                        Text($0.title)
                    }
                }
                .pickerStyle(.wheel)
            }

            // Subtitle
            Text(Localization.expireAfterSubtitle)
                .foregroundColor(Color(.textSubtle))
                .subheadlineStyle()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.done) {
                    viewModel.didTapDone()
                }
                .disabled(!viewModel.shouldEnableDoneButton)
            }
        }
        .animation(.easeInOut, value: showPicker)
    }
}

private extension SubscriptionExpiryView {
    enum Localization {
        static let expireAfter = NSLocalizedString("subscriptionExpiryView.expireAfter",
                                                   value: "Expire after",
                                                   comment: "Title for the expire after row in add or edit subscription expire after info screen.")
        static let done = NSLocalizedString("subscriptionExpiryView.done",
                                            value: "Done",
                                            comment: "Title of the button to save subscription's expire after info.")
        static let expireAfterSubtitle = NSLocalizedString(
            "subscriptionExpiryView.expireAfterSubtitle",
            value: "Automatically expire the subscription after this length of time. " +
            "This length is in addition to any free trial or amount of time provided before a synchronised first renewal date.",
            comment: "Subtitle text to explain subscription expire after value.")
    }
}

// MARK: Previews

struct SubscriptionExpiryView_Previews: PreviewProvider {
    static let viewModel = SubscriptionExpiryViewModel(subscription: .init(length: "1",
                                                                           period: .month,
                                                                           periodInterval: "1",
                                                                           price: "1",
                                                                           signUpFee: "1",
                                                                           trialLength: "12",
                                                                           trialPeriod: .day,
                                                                           oneTimeShipping: false,
                                                                           paymentSyncDate: "3",
                                                                           paymentSyncMonth: "01"),
                                                       completion: { _, _  in } )


    static var previews: some View {
        SubscriptionExpiryView(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        SubscriptionExpiryView(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        SubscriptionExpiryView(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font")
    }
}
