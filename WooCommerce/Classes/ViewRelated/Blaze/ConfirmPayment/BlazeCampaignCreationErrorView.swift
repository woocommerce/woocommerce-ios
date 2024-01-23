import SwiftUI

/// View for the error state of a Blaze campaign creation request.
struct BlazeCampaignCreationErrorView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var isShowingSupport = false

    private let onTryAgain: () -> Void
    private let onCancel: () -> Void

    init(onTryAgain: @escaping () -> Void,
         onCancel: @escaping () -> Void) {
        self.onTryAgain = onTryAgain
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.titlePadding) {
                Image(uiImage: .bigErrorIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.errorIconSize * scale)
                    .padding(.top, Layout.iconTopPadding)

                Text(Localization.title)
                    .bold()
                    .largeTitleStyle()

                VStack(alignment: .leading, spacing: Layout.contentPadding) {
                    Text(Localization.message)
                        .bodyStyle()

                    Text(Localization.noPaymentTaken)
                        .headlineStyle()

                    Text(Localization.suggestion)
                        .bodyStyle()
                }

                Button {
                    isShowingSupport = true
                } label: {
                    Label(Localization.getSupport, systemImage: "questionmark.circle")
                        .font(.body.weight(.semibold))
                }

                Spacer()
            }
            .padding(Layout.contentPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Layout.contentPadding) {
                Button(Localization.tryAgain, action: onTryAgain)
                    .buttonStyle(PrimaryButtonStyle())

                Button(Localization.cancel, action: onCancel)
                 .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Layout.contentPadding)
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $isShowingSupport) {
            supportForm
        }
    }
}

private extension BlazeCampaignCreationErrorView {
    var supportForm: some View {
        NavigationView {
            SupportForm(viewModel: SupportFormViewModel(sourceTag: Constants.supportTag, shouldHandleIdentity: true, onDismiss: {
                isShowingSupport = false
            }))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        isShowingSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private extension BlazeCampaignCreationErrorView {
    enum Layout {
        static let iconTopPadding: CGFloat = 40
        static let errorIconSize: CGFloat = 56
        static let contentPadding: CGFloat = 12
        static let titlePadding: CGFloat = 24
    }

    enum Constants {
        static let supportTag = "origin:blaze-native-campaign-creation"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "blazeCampaignCreationErrorView.title",
            value: "Error creating campaign",
            comment: "Title of the Blaze campaign creation error screen."
        )
        static let message = NSLocalizedString(
            "blazeCampaignCreationErrorView.message",
            value: "Something's not quite right.\nWe couldn't create your campaign.",
            comment: "Message on the Blaze campaign creation error screen. " +
            "Keep '\n' as-is as it signals a line break."
        )
        static let noPaymentTaken = NSLocalizedString(
            "blazeCampaignCreationErrorView.noPaymentTaken",
            value: "No payment has been taken.",
            comment: "Message on the Blaze campaign creation error screen."
        )
        static let suggestion = NSLocalizedString(
            "blazeCampaignCreationErrorView.suggestion",
            value: "Please try again, or contact support for assistance.",
            comment: "Suggested message on the Blaze campaign creation error screen."
        )
        static let getSupport = NSLocalizedString(
            "blazeCampaignCreationErrorView.getSupport",
            value: "Get support",
            comment: "Button to get support on the Blaze campaign creation error screen."
        )
        static let tryAgain = NSLocalizedString(
            "blazeCampaignCreationErrorView.tryAgain",
            value: "Try Again",
            comment: "Button to try again on the Blaze campaign creation error screen."
        )
        static let cancel = NSLocalizedString(
            "blazeCampaignCreationErrorView.cancel",
            value: "Cancel Campaign",
            comment: "Button to dismiss the flow on the Blaze campaign creation error screen."
        )
        static let done = NSLocalizedString(
            "blazeCampaignCreationErrorView.done",
            value: "Done",
            comment: "Button to dismiss the support form from the Blaze campaign creation error screen."
        )
    }
}

#Preview {
    BlazeCampaignCreationErrorView(onTryAgain: {}, onCancel: {})
}
