import SwiftUI
import Yosemite
import ScrollViewSectionKit

struct InPersonPaymentsMenu: View {
    @ObservedObject private(set) var viewModel: InPersonPaymentsMenuViewModel

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    depositSummary
                        .background {
                            Color(UIColor.systemBackground)
                                .ignoresSafeArea()
                        }

                    ScrollViewSection {
                        PaymentsRow(image: Image(uiImage: .moneyIcon),
                                    title: Localization.collectPayment)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier(AccessibilityIdentifiers.collectPaymentRow)
                        .onTapGesture {
                            viewModel.collectPaymentTapped()
                        }
                    } header: {
                        Text(Localization.paymentActionsSectionTitle.uppercased())
                            .accessibilityAddTraits(.isHeader)
                    }

                    if let payInPersonToggleViewModel = viewModel.payInPersonToggleViewModel as? InPersonPaymentsCashOnDeliveryToggleRowViewModel {
                        ScrollViewSection {
                            PaymentsToggleRow(
                                image: Image(uiImage: .creditCardIcon),
                                title: Localization.toggleEnableCashOnDelivery,
                                toggleRowViewModel: payInPersonToggleViewModel)
                            .customOpenURL(binding: $viewModel.safariSheetURL)
                            .padding(.vertical, Layout.cellVerticalPadding)
                        } header: {
                            Text(Localization.paymentSettingsSectionTitle.uppercased())
                                .accessibilityAddTraits(.isHeader)
                        }
                    }

                    ScrollViewSection {
                        PaymentsRow(image: Image(uiImage: .tapToPayOnIPhoneIcon),
                                    title: viewModel.setUpTryOutTapToPayRowTitle,
                                    shouldBadgeImage: viewModel.shouldBadgeTapToPayOnIPhone)
                        .accessibilityAddTraits(.isButton)
                        .onTapGesture {
                            viewModel.setUpTryOutTapToPayTapped()
                        }
                        .sheet(isPresented: $viewModel.presentSetUpTryOutTapToPay,
                               onDismiss: {
                            Task { @MainActor in
                                await viewModel.onAppear()
                            }
                        }) {
                            NavigationStack {
                                TapToPaySettingsFlowPresentingView(
                                    configuration: viewModel.cardPresentPaymentsConfiguration,
                                    siteID: viewModel.siteID,
                                    onboardingUseCase: viewModel.onboardingUseCase)
                                .navigationBarHidden(true)
                            }
                        }

                        Button {
                            viewModel.aboutTapToPayTapped()
                        } label: {
                            PaymentsRow(image: Image(uiImage: .infoOutlineImage),
                                        title: Localization.aboutTapToPayOnIPhone,
                                        isActive: $viewModel.presentAboutTapToPay) {
                                AboutTapToPayView(viewModel: viewModel.aboutTapToPayViewModel)
                            }
                        }
                        .buttonStyle(.scrollViewRow)

                        PaymentsRow(image: Image(uiImage: .feedbackOutlineIcon.withRenderingMode(.alwaysTemplate)),
                                    title: Localization.tapToPayOnIPhoneFeedback)
                        .accessibility(addTraits: .isButton)
                        .foregroundColor(Color(uiColor: .textLink))
                        .onTapGesture {
                            viewModel.tapToPayFeedbackTapped()
                        }
                        .sheet(isPresented: $viewModel.presentTapToPayFeedback) {
                            Survey(source: .tapToPayFirstPayment)
                        }
                        .renderedIf(viewModel.shouldShowTapToPayFeedbackRow)
                    } header: {
                        Text(Localization.tapToPaySectionTitle.uppercased())
                            .accessibilityAddTraits(.isHeader)
                    }
                    .renderedIf(viewModel.shouldShowTapToPaySection)

                    ScrollViewSection {
                        Button {
                            viewModel.purchaseCardReaderTapped()
                        } label: {
                            PaymentsRow(image: Image(uiImage: .shoppingCartIcon),
                                        title: Localization.purchaseCardReader,
                                        isActive: $viewModel.presentPurchaseCardReader) {
                                AuthenticatedWebView(isPresented: .constant(true),
                                                     viewModel: viewModel.purchaseCardReaderWebViewModel)
                            }
                        }
                        .buttonStyle(.scrollViewRow)

                        Button {
                            viewModel.manageCardReadersTapped()
                        } label: {
                            PaymentsRow(image: Image(uiImage: .creditCardIcon),
                                        title: Localization.manageCardReader)
                        }
                        .sheet(isPresented: $viewModel.presentManageCardReaders,
                               onDismiss: {
                            Task { @MainActor in
                                await viewModel.onAppear()
                            }
                        }) {
                            NavigationView {
                                CardReaderSettingsFlowPresentingView(
                                    configuration: viewModel.cardPresentPaymentsConfiguration,
                                    siteID: viewModel.siteID)
                                .navigationBarItems(leading: Button(Localization.done, action: {
                                    viewModel.presentManageCardReaders = false
                                }))
                            }
                        }
                        .buttonStyle(.scrollViewRow)
                        .disabled(viewModel.shouldDisableManageCardReaders)

                        Button {
                            viewModel.cardReaderManualsTapped()
                        } label: {
                            PaymentsRow(image: Image(uiImage: .cardReaderManualIcon),
                                        title: Localization.cardReaderManuals,
                                        isActive: $viewModel.presentCardReaderManuals) {
                                CardReaderManualsView()
                            }
                        }
                        .buttonStyle(.scrollViewRow)
                        .accessibilityIdentifier(AccessibilityIdentifiers.cardReaderManualRow)
                    } header: {
                        Text(Localization.cardReaderSectionTitle.uppercased())
                            .accessibilityAddTraits(.isHeader)
                    } footer: {
                        InPersonPaymentsLearnMore(viewModel: .inPersonPayments(source: .paymentsMenu),
                                                  showInfoIcon: false)
                        .customOpenURL(binding: $viewModel.safariSheetURL)
                    }
                    .renderedIf(viewModel.shouldShowCardReaderSection)

                    ScrollViewSection {
                        Button {
                            viewModel.managePaymentGatewaysTapped()
                        } label: {
                            PaymentsRow(image: Image(systemName: "rectangle.on.rectangle.angled"),
                                        title: Localization.managePaymentGateways,
                                        subtitle: viewModel.selectedPaymentGatewayName,
                                        isActive: $viewModel.presentManagePaymentGateways) {
                                InPersonPaymentsSelectPluginView(selectedPlugin: viewModel.selectedPaymentGatewayPlugin,
                                                                 onPluginSelected: viewModel.preferredPluginSelected)
                            }
                            .padding(.vertical, Layout.cellVerticalPadding)
                        }
                        .buttonStyle(.scrollViewRow)
                        .renderedIf(viewModel.shouldShowManagePaymentGatewaysRow)
                    }
                    .renderedIf(viewModel.shouldShowPaymentOptionsSection)
                }
            }
            .scrollViewSectionStyle(.insetGrouped)
            .safariSheet(url: $viewModel.safariSheetURL)
            .navigationDestination(isPresented: $viewModel.shouldShowOnboarding) {
                CardPresentPaymentsOnboardingView(viewModel: viewModel.onboardingViewModel)
            }
            .navigationDestination(isPresented: $viewModel.presentSupport) {
                SupportForm(isPresented: $viewModel.presentSupport,
                            viewModel: .init())
            }

            if let onboardingNotice = viewModel.cardPresentPaymentsOnboardingNotice {
                PermanentNoticeView(notice: onboardingNotice)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
        .background {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
        }
        .task {
            await viewModel.onAppear()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActivityIndicator(isAnimating: $viewModel.backgroundOnboardingInProgress,
                                  style: .medium)
            }
        }
        .navigationTitle(CardPresentPaymentsOnboardingView.Localization.title)
        .navigationDestination(for: InPersonPaymentsMenuNavigationDestination.self) { destination in
            if let orderViewModel = viewModel.orderViewModel {
                OrderFormPresentationWrapper(dismissHandler: {
                    viewModel.dismissPaymentCollection()
                    Task { @MainActor in
                        await viewModel.onAppear()
                    }
                },
                                             flow: .creation,
                                             dismissLabel: .backButton,
                                             viewModel: orderViewModel)
                .navigationBarHidden(true)
                .sheet(isPresented: $viewModel.presentCollectPaymentMigrationSheet, onDismiss: {
                    // Custom amount sheet needs to be presented when the migration sheet is dismissed to avoid conflicting modals.
                    if viewModel.presentCustomAmountAfterDismissingCollectPaymentMigrationSheet {
                        orderViewModel.addCustomAmount()
                    }
                }) {
                    SimplePaymentsMigrationView {
                        viewModel.presentCustomAmountAfterDismissingCollectPaymentMigrationSheet = true
                        viewModel.presentCollectPaymentMigrationSheet = false
                    }
                    .presentationDetents([.medium, .large])
                }

                .navigationDestination(for: CollectPaymentNavigationDestination.self) { destination in
                    if let paymentMethodsViewModel = viewModel.paymentMethodsViewModel {
                        PaymentMethodsWrapperHosted(viewModel: paymentMethodsViewModel,
                                                    dismiss: {
                            viewModel.dismissPaymentCollection()
                        })
                    } else {
                        EmptyView()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        guard viewModel.hasPresentedCollectPaymentMigrationSheet == false else {
                            return
                        }
                        viewModel.presentCollectPaymentMigrationSheet = true
                        viewModel.hasPresentedCollectPaymentMigrationSheet = true
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    var depositSummary: some View {
        if #available(iOS 16.0, *),
           viewModel.shouldShowDepositSummary {
            if viewModel.isLoadingDepositSummary {
                WooPaymentsDepositsOverviewView(viewModel: depositSummaryLoadingViewModel)
                    .redacted(reason: .placeholder)
                    .shimmering()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Localization.loadingDepositSummaryAccessibilityLabel)
            } else if let depositViewModel = viewModel.depositViewModel {
                WooPaymentsDepositsOverviewView(viewModel: depositViewModel)
            }
        } else {
            EmptyView()
        }
    }

    private var depositSummaryLoadingViewModel: WooPaymentsDepositsOverviewViewModel {
        .init(currencyViewModels: [.init(overview: .init(
            currency: .AED,
            automaticDeposits: false,
            depositInterval: .daily,
            pendingBalanceAmount: .zero,
            pendingDepositDays: 0,
            lastDeposit: nil,
            availableBalance: .zero))])
    }
}

private extension InPersonPaymentsMenu {
    enum Layout {
        static let cellVerticalPadding = CGFloat(8.0)
    }

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
        ).localizedCapitalized

        static let manageCardReader = NSLocalizedString(
            "menu.payments.cardReader.manage.row.title",
            value: "Manage Card Reader",
            comment: "Navigates to Card Reader management screen"
        ).localizedCapitalized

        static let managePaymentGateways = NSLocalizedString(
            "menu.payments.paymentGateway.manage.row.title",
            value: "Payment Provider",
            comment: "Navigates to Payment Gateway management screen"
        ).localizedCapitalized

        static let toggleEnableCashOnDelivery = NSLocalizedString(
            "menu.payments.payInPerson.toggle.row.title",
            value: "Pay in Person",
            comment: "Title for a switch on the In-Person Payments menu to enable Cash on Delivery"
        ).localizedCapitalized

        static let cardReaderManuals = NSLocalizedString(
            "menu.payments.cardReader.manuals.row.title",
            value: "Card Reader Manuals",
            comment: "Navigates to Card Reader Manuals screen"
        ).localizedCapitalized

        static let collectPayment = NSLocalizedString(
            "menu.payments.actions.collectPayment.row.title",
            value: "Collect Payment",
            comment: "Navigates to Collect a payment via the Simple Payment screen"
        ).localizedCapitalized

        static let aboutTapToPayOnIPhone = NSLocalizedString(
            "menu.payments.tapToPay.about.row.title",
            value: "About Tap to Pay",
            comment: "Navigates to the About Tap to Pay on iPhone screen, which explains the capabilities and limits " +
            "of Tap to Pay on iPhone, relevant to the store territory."
        ).localizedCapitalized

        static let tapToPayOnIPhoneFeedback = NSLocalizedString(
            "menu.payments.tapToPay.feedback.row.title",
            value: "Share Feedback",
            comment: "Navigates to a screen to share feedback about Tap to Pay on iPhone."
        ).localizedCapitalized

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

        static let loadingDepositSummaryAccessibilityLabel = NSLocalizedString(
            "menu.payments.depositSummary.loading.accessibilityLabel",
            value: "Loading balances...",
            comment: "An accessibility label used when the balances are loading on the payments menu"
        )
    }

    enum AccessibilityIdentifiers {
        static let collectPaymentRow = "collect-payment"
        static let cardReaderManualRow = "card-reader-manuals"
    }
}

struct InPersonPaymentsMenu_Previews: PreviewProvider {
    static let viewModel: InPersonPaymentsMenuViewModel = .init(
        siteID: 0,
        dependencies: .init(
            cardPresentPaymentsConfiguration: .init(country: .US),
            onboardingUseCase: CardPresentPaymentsOnboardingUseCase(),
            cardReaderSupportDeterminer: CardReaderSupportDeterminer(siteID: 0),
            wooPaymentsDepositService: WooPaymentsDepositService(siteID: 0, credentials: .init(authToken: ""))),
        navigationPath: .constant(NavigationPath()))
    static var previews: some View {
        NavigationStack {
            InPersonPaymentsMenu(viewModel: viewModel)
        }
    }
}
