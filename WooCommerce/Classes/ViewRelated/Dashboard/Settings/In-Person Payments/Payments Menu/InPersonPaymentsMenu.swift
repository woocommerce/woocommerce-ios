import SwiftUI

struct InPersonPaymentsMenu: View {
    @ObservedObject private(set) var viewModel: InPersonPaymentsMenuViewModel

    @State private var safariSheetURL: URL?

    @State private var showingSimplePayments: Bool = false

    var body: some View {
        List {
            Section(Localization.paymentActionsSectionTitle) {
                // Modal
                PaymentsRow(image: Image(uiImage: .moneyIcon),
                            title: Localization.collectPayment)
                .onTapGesture {
                    showingSimplePayments = true
                }
                .sheet(isPresented: $showingSimplePayments,
                       onDismiss: {
                    // log analytics, maybe prevent, better if we can defer to the SimplePaymentsVM
                }) {
                    NavigationView {
                        // TODO: fix IPP/TTP payments from this route – needs a rootVC
                        SimplePaymentsAmount(
                            dismiss: {
                                showingSimplePayments = false
                            },
                            viewModel: SimplePaymentsAmountViewModel(siteID: viewModel.siteID))
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }

            Section(Localization.paymentSettingsSectionTitle) {
                PaymentsToggleRow(
                    image: Image(uiImage: .creditCardIcon),
                    title: Localization.toggleEnableCashOnDelivery,
                    toggleRowViewModel: viewModel.payInPersonToggleViewModel)
                .customOpenURL(binding: $safariSheetURL)
            }

            Section(Localization.tapToPaySectionTitle) {
                // Modal
                NavigationLink(destination:
                                PaymentSettingsFlowPresentingView(
                                    viewModelsAndViews: viewModel.setUpTapToPayViewModelsAndViews)) {
                    PaymentsRow(image: Image(uiImage: .tapToPayOnIPhoneIcon),
                                title: viewModel.setUpTryOutTapToPayRowTitle)
                }

                NavigationLink(destination: AboutTapToPayView(viewModel: viewModel.aboutTapToPayViewModel)) {
                    PaymentsRow(image: Image(uiImage: .infoOutlineImage),
                                title: Localization.aboutTapToPayOnIPhone)
                }

                // Modal
                NavigationLink(destination: Survey(source: .tapToPayFirstPayment)) {
                    PaymentsRow(image: Image(uiImage: .feedbackOutlineIcon.withRenderingMode(.alwaysTemplate)),
                                title: Localization.tapToPayOnIPhoneFeedback)
                }
                .renderedIf(viewModel.shouldShowTapToPayFeedbackRow)
            }
            .renderedIf(viewModel.shouldShowTapToPaySection)

            Section {
                NavigationLink {
                    AuthenticatedWebView(isPresented: .constant(true),
                                         viewModel: viewModel.purchaseCardReaderWebViewModel)
                } label: {
                    PaymentsRow(image: Image(uiImage: .shoppingCartIcon),
                                title: Localization.purchaseCardReader)
                }

                NavigationLink {
                    PaymentSettingsFlowPresentingView(viewModelsAndViews: viewModel.manageCardReadersViewModelsAndViews)
                } label: {
                    PaymentsRow(image: Image(uiImage: .creditCardIcon),
                                title: Localization.manageCardReader)
                }
                .disabled(viewModel.shouldDisableManageCardReaders)

                NavigationLink {
                    CardReaderManualsView()
                } label: {
                    PaymentsRow(image: Image(uiImage: .cardReaderManualIcon),
                                title: Localization.cardReaderManuals)
                }
            } header: {
                Text(Localization.cardReaderSectionTitle)
            } footer: {
                InPersonPaymentsLearnMore(viewModel: .inPersonPayments(source: .paymentsMenu),
                                          showInfoIcon: false)
                    .customOpenURL(binding: $safariSheetURL)
            }
            .renderedIf(viewModel.shouldShowCardReaderSection)
        }
        .safariSheet(url: $safariSheetURL)
    }
}

private extension InPersonPaymentsMenu {
    enum Localization {
        static let cardReaderSectionTitle = NSLocalizedString(
            "menu.payments.cardReader.section.title",
            value: "Card readers",
            comment: "Title for the section related to card readers inside In-Person Payments settings")

        static let paymentOptionsSectionTitle = NSLocalizedString(
            "menu.payments.paymentOptions.section.title",
            value: "Payment options",
            comment: "Title for the section related to payments inside In-Person Payments settings")

        static let paymentActionsSectionTitle = NSLocalizedString(
            "menu.payments.actions.section.title",
            value: "Actions",
            comment: "Title for the section related to actions inside In-Person Payments settings")

        static let paymentSettingsSectionTitle = NSLocalizedString(
            "menu.payments.paymentSettings.section.title",
            value: "Settings",
            comment: "Title for the section related to changing payment settings inside the In-Person Payments menu")

        static let wooPaymentsDepositsSectionTitle = NSLocalizedString(
            "menu.payments.wooPaymentsDeposits.section.title",
            value: "Woo Payments Balance",
            comment: "Title for the section related to Woo Payments Deposits/Balances.")

        static let tapToPaySectionTitle = NSLocalizedString(
            "menu.payments.tapToPay.section.title",
            value: "Tap to Pay",
            comment: "Title for the Tap to Pay section in the In-Person payments settings")

        static let wooPaymentsDeposits = NSLocalizedString(
            "menu.payments.wooPaymentsDeposits.row.title",
            value: "Woo Payments Balance",
            comment: "Title for the row related to Woo Payments Deposits/Balances.")

        static let purchaseCardReader = NSLocalizedString(
            "menu.payments.cardReader.purchase.row.title",
            value: "Order Card Reader",
            comment: "Navigates to Card Reader purchase screen"
        )

        static let manageCardReader = NSLocalizedString(
            "menu.payments.cardReader.manage.row.title",
            value: "Manage Card Reader",
            comment: "Navigates to Card Reader management screen"
        )

        static let managePaymentGateways = NSLocalizedString(
            "menu.payments.paymentGateway.manage.row.title",
            value: "Payment Provider",
            comment: "Navigates to Payment Gateway management screen"
        )

        static let toggleEnableCashOnDelivery = NSLocalizedString(
            "menu.payments.payInPerson.toggle.row.title",
            value: "Pay in Person",
            comment: "Title for a switch on the In-Person Payments menu to enable Cash on Delivery"
        )

        static let cardReaderManuals = NSLocalizedString(
            "menu.payments.cardReader.manuals.row.title",
            value: "Card Reader Manuals",
            comment: "Navigates to Card Reader Manuals screen"
        )

        static let collectPayment = NSLocalizedString(
            "menu.payments.actions.collectPayment.row.title",
            value: "Collect Payment",
            comment: "Navigates to Collect a payment via the Simple Payment screen"
        )

        static let aboutTapToPayOnIPhone = NSLocalizedString(
            "menu.payments.tapToPay.about.row.title",
            value: "About Tap to Pay",
            comment: "Navigates to the About Tap to Pay on iPhone screen, which explains the capabilities and limits " +
            "of Tap to Pay on iPhone, relevant to the store territory.")

        static let tapToPayOnIPhoneFeedback = NSLocalizedString(
            "menu.payments.tapToPay.feedback.row.title",
            value: "Share Feedback",
            comment: "Navigates to a screen to share feedback about Tap to Pay on iPhone.")

        static let inPersonPaymentsSetupNotFinishedNotice = NSLocalizedString(
            "menu.payments.inPersonPayments.setup.incomplete.notice.title",
            value: "In-Person Payments setup is incomplete.",
            comment: "Shows a notice pointing out that the user didn't finish the In-Person Payments setup, so some functionalities are disabled."
        )

        static let inPersonPaymentsSetupNotFinishedNoticeButtonTitle = NSLocalizedString(
            "menu.payments.inPersonPayments.setup.incomplete.notice.button.title",
            value: "Continue setup",
            comment: "Call to Action to finish the setup of In-Person Payments in the Menu"
        )

        static let done = NSLocalizedString(
            "menu.payments.wooPaymentsDeposits.navigation.done.button.title",
            value: "Done",
            comment: "Title for a done button in the navigation bar")

        static let inPersonPaymentsLearnMoreText = NSLocalizedString(
            "menu.payments.inPersonPayments.learnMore.text",
            value: "%1$@ about In‑Person Payments",
            comment: """
                     A label prompting users to learn more about In-Person Payments.
                     The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                     If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it.
                     %1$@ is a placeholder that always replaced with \"Learn more\" string,
                     which should be translated separately and considered part of this sentence.
                     """
        )

        static let learnMoreLink = NSLocalizedString(
            "menu.payments.inPersonPayments.learnMore.link",
            value: "Learn more",
            comment: """
                     A label prompting users to learn more about card readers.
                     This part is the link to the website, and forms part of a longer sentence which it should be considered a part of.
                     """
        )
    }
}

struct InPersonPaymentsMenu_Previews: PreviewProvider {
    static let viewModel: InPersonPaymentsMenuViewModel = .init(
        siteID: 0,
        dependencies: .init(
            cardPresentPaymentsConfiguration: .init(country: .US),
            onboardingUseCase: CardPresentPaymentsOnboardingUseCase(),
            cardReaderSupportDeterminer: CardReaderSupportDeterminer(siteID: 0)))
    static var previews: some View {
        InPersonPaymentsMenu(viewModel: viewModel)
    }
}