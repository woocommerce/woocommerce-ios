import SwiftUI
import class Photos.PHAsset

/// View to confirm the payment method before creating a Blaze campaign.
struct BlazeConfirmPaymentView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    @ObservedObject private var viewModel: BlazeConfirmPaymentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var externalURL: URL?
    @State private var showingAddPaymentWebView: Bool = false
    @State private var isShowingSupport = false

    private let agreementText: NSAttributedString = {
        let content = String.localizedStringWithFormat(Localization.agreement, Localization.termsOfService, Localization.adPolicy, Localization.learnMore)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let mutableAttributedText = NSMutableAttributedString(
            string: content,
            attributes: [.font: UIFont.caption1,
                         .foregroundColor: UIColor.secondaryLabel,
                         .paragraphStyle: paragraph]
        )

        mutableAttributedText.setAsLink(textToFind: Localization.termsOfService,
                                        linkURL: Constants.termsLink)
        mutableAttributedText.setAsLink(textToFind: Localization.adPolicy,
                                        linkURL: Constants.adPolicyLink)
        mutableAttributedText.setAsLink(textToFind: Localization.learnMore,
                                        linkURL: Constants.learnMoreLink)
        return mutableAttributedText
    }()

    init(viewModel: BlazeConfirmPaymentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.contentPadding) {

                totalAmountView
                    .padding(.horizontal, Layout.contentPadding)

                Divider()

                if !viewModel.isFetchingPaymentInfo {
                    if viewModel.selectedPaymentMethod == nil {
                        addPaymentMethodButton
                            .padding(.horizontal, Layout.contentPadding)
                    } else {
                        cardDetailView
                            .padding(.horizontal, Layout.contentPadding)
                    }

                } else {
                    loadingView
                        .padding(.horizontal, Layout.contentPadding)
                }

                Divider()
            }
            .padding(.vertical, Layout.contentPadding)
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.help) {
                    isShowingSupport = true
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            footerView
        }
        .task {
            await viewModel.updatePaymentInfo()
        }
        .alert(Text(Localization.errorMessage), isPresented: $viewModel.shouldDisplayPaymentErrorAlert, actions: {
            Button(Localization.tryAgain) {
                Task {
                    await viewModel.updatePaymentInfo()
                }
            }
        })
        .sheet(isPresented: $viewModel.isCreatingCampaign) {
            BlazeCampaignCreationLoadingView()
                .interactiveDismissDisabled()
        }
        .sheet(item: $viewModel.campaignCreationError) { error in
            BlazeCampaignCreationErrorView(error: error,
                                           onTryAgain: {
                viewModel.campaignCreationError = nil
                Task {
                    await viewModel.submitCampaign()
                }
            }, onCancel: {
                viewModel.campaignCreationError = nil
                dismiss()
            })
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showAddPaymentSheet) {
            if let paymentMethodsViewModel = viewModel.paymentMethodsViewModel {
                BlazePaymentMethodsView(viewModel: paymentMethodsViewModel)
            }
        }
        .sheet(isPresented: $showingAddPaymentWebView, content: {
            if let viewModel = viewModel.addPaymentWebViewModel {
                BlazeAddPaymentMethodWebView(viewModel: viewModel)
            }
        })
        .sheet(isPresented: $isShowingSupport) {
            supportForm
        }
    }
}

private extension BlazeConfirmPaymentView {
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $isShowingSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag))
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


private extension BlazeConfirmPaymentView {
    var totalAmountView: some View {
        VStack(alignment: .leading, spacing: Layout.contentPadding) {
            Text(Localization.paymentTotals)
                .fontWeight(.semibold)
                .bodyStyle()

            HStack {
                Text(Localization.blazeCampaign)
                    .bodyStyle()

                Spacer()

                Text(viewModel.totalAmount)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Text(Localization.total)
                    .bold()

                Spacer()

                Text(viewModel.totalAmountWithCurrency)
                    .bold()
            }
            .bodyStyle()
        }
    }

    var cardDetailView: some View {
        Button {
            viewModel.showAddPaymentSheet = true
        } label: {
            if let icon = viewModel.cardIcon {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.cardIconWidth * scale)
            }

            VStack(alignment: .leading) {
                if let type = viewModel.cardTypeName {
                    Text(type)
                        .bodyStyle()
                }

                if let name = viewModel.cardName {
                    Text(name)
                        .foregroundColor(.secondary)
                        .captionStyle()
                }
            }

            Spacer()

            Image(systemName: "chevron.forward")
                .secondaryBodyStyle()
        }
    }

    var addPaymentMethodButton: some View {
        Button {
            showingAddPaymentWebView = true
        } label: {
            HStack {
                Text(Localization.addPaymentMethod)
                Spacer()
                Image(systemName: "chevron.forward")
                    .secondaryBodyStyle()
            }
        }
    }

    var loadingView: some View {
        HStack {
            Text(Localization.loading)
                .secondaryBodyStyle()
            Spacer()
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
        }
    }

    var footerView: some View {
        VStack(spacing: Layout.contentPadding) {
            Divider()
            Button(Localization.submitButton) {
                Task {
                    await viewModel.submitCampaign()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.shouldDisableCampaignCreation)
            .padding(.horizontal, Layout.contentPadding)

            AttributedText(agreementText)
                .padding(.horizontal, Layout.contentPadding)
                .environment(\.openURL, OpenURLAction { url in
                    externalURL = url
                    return .handled
                })
                .safariSheet(url: $externalURL)
        }
        .padding(.vertical, Layout.contentPadding)
        .background(Color(.systemBackground))
    }
}

private extension BlazeConfirmPaymentView {

    enum Layout {
        static let contentPadding: CGFloat = 16
        static let cardIconWidth: CGFloat = 35
    }

    enum Constants {
        static let termsLink = "https://wordpress.com/tos/"
        static let adPolicyLink = "https://automattic.com/advertising-policy/"
        static let learnMoreLink = "https://wordpress.com/support/promote-a-post/"
        static let supportTag = "origin:blaze-native-campaign-creation"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "blazeConfirmPaymentView.title",
            value: "Payment",
            comment: "Title of the Payment view in the Blaze campaign creation flow"
        )
        static let submitButton = NSLocalizedString(
            "blazeConfirmPaymentView.submitButton",
            value: "Submit Campaign",
            comment: "Action button on the Payment screen in the Blaze campaign creation flow"
        )
        static let paymentTotals = NSLocalizedString(
            "blazeConfirmPaymentView.paymentTotals",
            value: "Payment totals",
            comment: "Section title on the Payment screen in the Blaze campaign creation flow"
        )
        static let blazeCampaign = NSLocalizedString(
            "blazeConfirmPaymentView.blazeCampaign",
            value: "Blaze campaign",
            comment: "Item to be charged on the Payment screen in the Blaze campaign creation flow"
        )
        static let total = NSLocalizedString(
            "blazeConfirmPaymentView.total",
            value: "Total",
            comment: "Title of the total amount to be charged on the Payment screen in the Blaze campaign creation flow"
        )
        static let addPaymentMethod = NSLocalizedString(
            "blazeConfirmPaymentView.addPaymentMethod",
            value: "Add a payment method",
            comment: "Button for adding a payment method on the Payment screen in the Blaze campaign creation flow"
        )
        static let loading = NSLocalizedString(
            "blazeConfirmPaymentView.loading",
            value: "Loading payment methods...",
            comment: "Text for the loading state on the Payment screen in the Blaze campaign creation flow"
        )
        static let agreement = NSLocalizedString(
            "blazeConfirmPaymentView.agreement",
            value: "By clicking \"Submit Campaign\" you agree to the %1$@ and " +
            "%2$@, and authorize your payment method to be charged for " +
            "the budget and duration you chose. %3$@ about how budgets and payments for Promoted Posts work.",
            comment: "Content of the agreement at the end of the Payment screen in the Blaze campaign creation flow. Read likes: " +
            "By clicking \"Submit campaign\" you agree to the Terms of Service and " +
                 "Advertising Policy, and authorize your payment method to be charged for " +
                 "the budget and duration you chose. Learn more about how budgets and payments for Promoted Posts work."
        )
        static let termsOfService = NSLocalizedString(
            "blazeConfirmPaymentView.terms",
            value: "Terms of Service",
            comment: "The terms to be agreed upon on the Payment screen in the Blaze campaign creation flow."
        )
        static let adPolicy = NSLocalizedString(
            "blazeConfirmPaymentView.adPolicy",
            value: "Advertising Policy",
            comment: "The action to be agreed upon on the Payment screen in the Blaze campaign creation flow."
        )
        static let learnMore = NSLocalizedString(
            "blazeConfirmPaymentView.learnMore",
            value: "Learn more",
            comment: "Link to guide for promoted posts on the Payment screen in the Blaze campaign creation flow."
        )
        static let errorMessage = NSLocalizedString(
            "blazeConfirmPaymentView.errorMessage",
            value: "Error loading your payment methods",
            comment: "Error message displayed when fetching payment methods failed on the Payment screen in the Blaze campaign creation flow."
        )
        static let tryAgain = NSLocalizedString(
            "blazeConfirmPaymentView.tryAgain",
            value: "Try Again",
            comment: "Button to retry when fetching payment methods failed on the Payment screen in the Blaze campaign creation flow."
        )

        static let help = NSLocalizedString(
            "blazeConfirmPaymentView.help",
            value: "Help",
            comment: "Button to contact support on the Blaze confirm payment view screen."
        )

        static let done = NSLocalizedString(
            "blazeConfirmPaymentView.done",
            value: "Done",
            comment: "Button to dismiss the support form from the Blaze confirm payment view screen."
        )
    }
}

#Preview {
    BlazeConfirmPaymentView(viewModel: BlazeConfirmPaymentViewModel(
        productID: 123,
        siteID: 123,
        campaignInfo: .init(origin: "test",
                            originVersion: "1.0",
                            paymentMethodID: "pid",
                            startDate: Date(),
                            endDate: Date(),
                            timeZone: "US-NY",
                            budget: .init(mode: .total, amount: 35.0, currency: "USD"),
                            isEvergreen: true,
                            siteName: "iPhone 15",
                            textSnippet: "Fancy new phone",
                            targetUrl: "https://example.com",
                            urlParams: "",
                            mainImage: .init(url: "https://example.com", mimeType: "png"),
                            targeting: nil,
                            targetUrn: "",
                            type: "product"),
        image: .init(image: .iconBolt, source: .asset(asset: PHAsset())),
        onCompletion: {}))
}
