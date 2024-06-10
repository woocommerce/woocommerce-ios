import SwiftUI
import Yosemite
import WooFoundation

struct AboutTapToPayView: View {
    @ObservedObject var viewModel: AboutTapToPayViewModel
    @State private var showingWebView: Bool = false
    @State private var showingSetUpFlow: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        Text(Localization.aboutTapToPayHeading)
                            .font(.title2.bold())
                        Text(Localization.aboutTapToPayDescription)
                    }
                    .padding(.vertical)

                    AboutTapToPayContactlessLimitView(
                        viewModel: AboutTapToPayContactlessLimitViewModel(configuration: viewModel.configuration))
                    .renderedIf(viewModel.shouldShowContactlessLimit)

                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        Text(Localization.howItWorksHeading)
                            .headlineStyle()
                        Text(Localization.howItWorksStep1)
                        Text(Localization.howItWorksStep2)
                        Text(Localization.howItWorksStep3)
                        Text(Localization.howItWorksStep4)
                        Text(Localization.howItWorksStep5)
                    }
                    .padding(.vertical)

                    Text(String(format: Localization.systemRequirementsDetails,
                                viewModel.formattedMinimumOperatingSystemVersionForTapToPay))
                        .footnoteStyle(isError: false)
                }
                .padding()
            }

            Spacer()

            Divider().renderedIf(viewModel.shouldShowButton)

            VStack(alignment: .leading, spacing: Layout.spacing) {
                Button(Localization.setUpTapToPayOnIPhoneButtonTitle) {
                    showingSetUpFlow = true
                }
                .buttonStyle(PrimaryButtonStyle())

                InPersonPaymentsLearnMore(viewModel: .tapToPay(source: .aboutTapToPay))
                    .padding(.vertical, Layout.learnMorePadding)
                    .customOpenURL(action: { _ in
                        showingWebView = true
                    })
            }
            .padding()
            .renderedIf(viewModel.shouldShowButton)
        }
        .sheet(isPresented: $showingSetUpFlow,
               onDismiss: viewModel.setUpFlowDismissed,
               content: {
            NavigationView {
                PaymentSettingsFlowPresentingView(
                    viewModelsAndViews: SetUpTapToPayViewModelsOrderedList(
                        siteID: viewModel.siteID,
                        configuration: viewModel.configuration,
                        onboardingUseCase: viewModel.cardPresentPaymentsOnboardingUseCase))
                .navigationBarHidden(true)
            }
        })
        .sheet(isPresented: $showingWebView) {
            WebViewSheet(viewModel: viewModel.webViewModel) {
                showingWebView = false
            }
        }
        .navigationTitle(Localization.aboutTapToPayNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutTapToPayView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutTapToPayView(viewModel: AboutTapToPayViewModel(
                siteID: 123,
                configuration: .init(country: .GB),
                cardReaderSupportDeterminer: nil))
        }
    }
}

private extension AboutTapToPayView {
    enum Localization {
        static let aboutTapToPayHeading = NSLocalizedString(
            "What is Tap to Pay on iPhone?",
            comment: "Main heading for the About Tap to Pay on iPhone screen")

        static let aboutTapToPayDescription = NSLocalizedString(
            "Tap to Pay on iPhone lets you accept all types of contactless payments – from physical debit and credit " +
            "cards, to Apple Pay and other digital wallets – without the need to purchase a physical card reader.",
            comment: "Description of Tap to Pay on iPhone shown on the About Tap to Pay on iPhone screen, as an intro.")

        static let howItWorksHeading = NSLocalizedString(
            "How it works",
            comment: "Headline for the 'How it works' section on the About Tap to Pay on iPhone screen, which " +
            "describes the steps required to take a payment.")

        static let howItWorksStep1 = NSLocalizedString(
            "1. Create an order",
            comment: "Step 1 of the 'How it works' list, instructing the merchant to prepare an order for payment")

        static let howItWorksStep2 = NSLocalizedString(
            "2. Tap “Collect Payment” and choose “Tap to Pay on iPhone”.",
            comment: "Step 2 of the 'How it works' list, instructing the merchant to how to select Tap to Pay payments")

        static let howItWorksStep3 = NSLocalizedString(
            "3. Present your iPhone to the customer.",
            comment: "Step 3 of the 'How it works' list, instructing the merchant to present the phone to the shopper")

        static let howItWorksStep4 = NSLocalizedString(
            "4. Your customer holds their card horizontally at the top of your iPhone, over the contactless symbol.",
            comment: "Step 4 of the 'How it works' list, informing the merchant of how a shopper should present their card")

        static let howItWorksStep5 = NSLocalizedString(
            "5. After you see the “Done” checkmark, your store will process the payment, and the transaction will be complete.",
            comment: "Step 5 of the 'How it works' list, instructing the merchant to wait until processing is complete.")

        static let systemRequirementsDetails = NSLocalizedString(
            "Requires iPhone XS or later with iOS %1$@ or later. The Contactless Symbol is a trademark owned by and " +
            "used with permission of EMVCo, LLC.",
            comment: "Requirements for Tap to Pay on iPhone, and other small print shown on the About Tap to Pay on " +
            "iPhone screen. %1$@ will be replaced with the relevant iOS version number.")

        static let setUpTapToPayOnIPhoneButtonTitle = NSLocalizedString(
            "Set Up Tap to Pay on iPhone",
            comment: "Button title for the main CTA on the About Tap to Pay on iPhone screen. The button opens the " +
            "Set Up Tap to Pay on iPhone flow.")

        static let aboutTapToPayNavigationTitle = NSLocalizedString(
            "About Tap to Pay on iPhone",
            comment: "Navigation title for the About Tap to Pay on iPhone Screen.")
    }

    enum Layout {
        static let spacing: CGFloat = 8
        static let learnMorePadding: CGFloat = 8
    }
}


struct AboutTapToPayContactlessLimitView: View {
    let viewModel: AboutTapToPayContactlessLimitViewModel
    @State private var showingWebView: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            HStack {
                Image(systemName: "info.circle")
                Text(Localization.importantInformation)
            }
            .headlineStyle()
            Text(viewModel.contactlessLimitDetails)
            Text(Localization.overLimitSuggestion)
            Button(Localization.limitButtonTitle) {
                viewModel.orderCardReaderPressed()
                showingWebView = true
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.withColorStudio(
            name: .wooCommercePurple,
            shade: .shade0))
        .cornerRadius(Layout.cornerRadius)
        .sheet(isPresented: $showingWebView) {
            WebViewSheet(viewModel: viewModel.webViewModel) {
                showingWebView = false
            }
        }
    }
}

private extension AboutTapToPayContactlessLimitView {
    enum Localization {
        static let importantInformation = NSLocalizedString(
            "Important information",
            comment: "Heading for the details pane showing the contactless limit on About Tap to Pay")

        static let overLimitSuggestion = NSLocalizedString(
            "To accept payments above this limit, consider purchasing a card reader.",
            comment: "A suggestion to buy a hardware card reader to handle transactions above the contactless limit, " +
            "shown on the About Tap to Pay screen")

        static let limitButtonTitle = NSLocalizedString(
            "Learn more about card readers",
            comment: "A button to view more about hardware card readers to handle transactions above the contactless " +
            "limit, shown on the About Tap to Pay screen")
    }

    enum Layout {
        static let spacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
    }
}

struct AboutTapToPayViewInNavigationView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: AboutTapToPayViewModel

    var body: some View {
        NavigationView {
            AboutTapToPayView(viewModel: viewModel)
            .toolbar() {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.doneButton) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension AboutTapToPayViewInNavigationView {
    enum Localization {
        static let doneButton = NSLocalizedString(
            "Done",
            comment: "Done navigation button in About Tap to Pay on iPhone screen, when presented from the set up flow")
    }
}
