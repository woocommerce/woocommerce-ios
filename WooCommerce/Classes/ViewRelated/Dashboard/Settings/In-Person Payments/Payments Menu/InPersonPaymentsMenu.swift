import SwiftUI
import Yosemite
import ScrollViewSectionKit

struct InPersonPaymentsMenu: View {
    @ObservedObject private(set) var viewModel: InPersonPaymentsMenuViewModel

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    payoutSummary
                        .background {
                            Color(UIColor.systemBackground)
                                .ignoresSafeArea()
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
                            TapToPaySettingsFlowPresentingView(
                                configuration: viewModel.cardPresentPaymentsConfiguration,
                                siteID: viewModel.siteID,
                                onboardingUseCase: viewModel.onboardingUseCase)
                        }

                        PaymentsRow(image: Image(uiImage: .infoOutlineImage),
                                    title: Localization.aboutTapToPayOnIPhone)
                        .accessibilityAddTraits(.isButton)
                        .onTapGesture {
                            viewModel.aboutTapToPayTapped()
                        }
                        .sheet(isPresented: $viewModel.presentAboutTapToPay,
                               onDismiss: {
                            Task { @MainActor in
                                await viewModel.onAppear()
                            }
                        }) {
                            TapToPayEducationView(viewModel: .init(flow: .about,
                                                                   completion: { result in
                                switch result {
                                case .setUpTapToPay:
                                    viewModel.presentSetUpTryOutTapToPay = true
                                default:
                                    break
                                }
                            }))
                        }
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
                                        title: Localization.purchaseCardReader)
                        }
                        .buttonStyle(.scrollViewRow)
                        .navigationDestination(isPresented: $viewModel.presentPurchaseCardReader) {
                            AuthenticatedWebView(isPresented: .constant(true),
                                                 viewModel: viewModel.purchaseCardReaderWebViewModel)
                        }

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
                                        title: Localization.cardReaderManuals)
                        }
                        .buttonStyle(.scrollViewRow)
                        .navigationDestination(isPresented: $viewModel.presentCardReaderManuals) {
                            CardReaderManualsView()
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.cardReaderManualRow)
                    } header: {
                        Text(Localization.cardReaderSectionTitle.uppercased())
                            .accessibilityAddTraits(.isHeader)
                    } footer: {
                        InPersonPaymentsLearnMore(viewModel: .inPersonPayments(source: .paymentsMenu,
                                                                               paymentGateway: viewModel.selectedPaymentGatewayPlugin),
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
                                        subtitle: viewModel.selectedPaymentGatewayName)
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
            .navigationDestination(isPresented: $viewModel.presentManagePaymentGateways) {
                InPersonPaymentsSelectPluginView(selectedPlugin: viewModel.selectedPaymentGatewayPlugin,
                                                 onPluginSelected: viewModel.preferredPluginSelected)
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
                if viewModel.backgroundOnboardingInProgress {
                    ActivityIndicator(isAnimating: $viewModel.backgroundOnboardingInProgress,
                                      style: .medium)
                }
            }
        }
        .navigationTitle(CardPresentPaymentsOnboardingView.Localization.title)
    }

    @ViewBuilder
    var payoutSummary: some View {
        if viewModel.shouldShowPayoutSummary {
            if viewModel.isLoadingPayoutSummary {
                WooPaymentsPayoutsOverviewView(viewModel: payoutSummaryLoadingViewModel)
                    .redacted(reason: .placeholder)
                    .shimmering()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Localization.loadingPayoutSummaryAccessibilityLabel)
            } else if let payoutViewModel = viewModel.payoutViewModel {
                WooPaymentsPayoutsOverviewView(viewModel: payoutViewModel)
            }
        }
    }

    private var payoutSummaryLoadingViewModel: WooPaymentsPayoutsOverviewViewModel {
        .init(currencyViewModels: [.init(overview: .init(
            currency: .AED,
            automaticPayouts: false,
            payoutInterval: .daily,
            pendingBalanceAmount: .zero,
            pendingPayoutDays: 0,
            lastPayout: nil,
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

        static let paymentSettingsSectionTitle = NSLocalizedString(
            "menu.payments.paymentSettings.section.title",
            value: "Settings",
            comment: "Title for the section related to changing payment settings inside the In-Person Payments menu")

        static let wooPaymentsPayoutsSectionTitle = NSLocalizedString(
            "menu.payments.wooPaymentsPayouts.section.title",
            value: "Woo Payments Balance",
            comment: "Title for the section related to Woo Payments Payouts/Balances.")

        static let tapToPaySectionTitle = NSLocalizedString(
            "menu.payments.tapToPay.section.title",
            value: "Tap to Pay",
            comment: "Title for the Tap to Pay section in the In-Person payments settings")

        static let wooPaymentsPayouts = NSLocalizedString(
            "menu.payments.wooPaymentsPayouts.row.title",
            value: "Woo Payments Balance",
            comment: "Title for the row related to Woo Payments Payouts/Balances.")

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

        static let aboutTapToPayOnIPhone = NSLocalizedString(
            "menu.payments.tapToPay.about.row.title",
            value: "About Tap to Pay",
            comment: "Navigates to the About Tap to Pay on iPhone screen, which explains the capabilities and limits " +
            "of Tap to Pay on iPhone, relevant to the store territory."
        )

        static let done = NSLocalizedString(
            "menu.payments.wooPaymentsPayouts.navigation.done.button.title",
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

        static let loadingPayoutSummaryAccessibilityLabel = NSLocalizedString(
            "menu.payments.payoutSummary.loading.accessibilityLabel",
            value: "Loading balances...",
            comment: "An accessibility label used when the balances are loading on the payments menu"
        )
    }

    enum AccessibilityIdentifiers {
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
            wooPaymentsPayoutService: WooPaymentsPayoutService(
                siteID: 0,
                credentials: .init(authToken: ""),
                selectedSite: ServiceLocator.stores.sessionManager.defaultSitePublisher
                    .map { $0?.toJetpackSite() }
                    .eraseToAnyPublisher(),
                appPasswordSupportState: ApplicationPasswordsExperimentState()
                    .$isAvailableAndEnabled
                    .eraseToAnyPublisher()
            )
        )
    )
    static var previews: some View {
        NavigationStack {
            InPersonPaymentsMenu(viewModel: viewModel)
        }
    }
}
