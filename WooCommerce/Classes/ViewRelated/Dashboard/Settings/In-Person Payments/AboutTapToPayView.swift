import SwiftUI
import WooFoundation

struct AboutTapToPayView: View {
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack {
                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        Text(Localization.aboutTapToPayHeading)
                            .font(.title2.bold())
                        Text(Localization.aboutTapToPayDescription)
                    }
                    .padding(.vertical)

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

                    Text(Localization.systemRequirementsDetails)
                        .footnoteStyle(isError: false)
                }
                .padding()
            }

            Spacer()

            Divider()

            VStack(alignment: .leading, spacing: Layout.spacing) {
                Button(Localization.setUpTapToPayOnIPhoneButtonTitle) {
                    // no-op
                }
                .buttonStyle(PrimaryButtonStyle())

                InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel())
            }
            .padding()
        }
        .fixedSize(horizontal: false, vertical: true)
        .navigationTitle(Localization.aboutTapToPayNavigationTitle)
    }
}

#Preview {
    NavigationView {
        AboutTapToPayView()
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
            "1. Create an order or collect a payment",
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
            "Requires iPhone XS or later with iOS 16 or later. The Contactless Symbol is a trademark owned by and " +
            "used with permission of EMVCo, LLC.",
            comment: "Requirements for Tap to Pay on iPhone, and other small print shown on the About Tap to Pay on " +
            "iPhone screen.")

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
    }
}
