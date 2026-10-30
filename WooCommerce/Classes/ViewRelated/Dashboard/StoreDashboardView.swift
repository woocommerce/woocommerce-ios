import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask
import enum WooFoundation.ConnectivityStatus

/// Design-system dashboard shell.
///
/// Card cases deliberately use their legacy implementations during the shell migration.
/// Each case is replaced by its dedicated design-system card in the follow-up slices.
struct StoreDashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var currentSite: Site?
    @State private var dismissedJetpackBenefitBanner = false
    @State private var storePlanState: StorePlanSyncState = .loading
    @State private var connectivityStatus: ConnectivityStatus = .notReachable

    private let actions: StoreDashboardActions
    private let storePlanSynchronizer = ServiceLocator.storePlanSynchronizer
    private let connectivityObserver = ServiceLocator.connectivityObserver

    init(viewModel: DashboardViewModel, actions: StoreDashboardActions) {
        self.viewModel = viewModel
        self.actions = actions
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Layout.cardSpacing) {
                    Text(currentSite?.name ?? Localization.title)
                        .accessibilityIdentifier("my-store-title")
                        .storeTextStyle(.titleMedium.emphasized)
                        .foregroundStyle(.storeOnSurface)
                        .padding(.horizontal, Layout.outerPadding)
                        .padding(.bottom, StoreSpacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .renderedIf(verticalSizeClass == .regular)

                    featureAnnouncementCard
                        .padding(.horizontal, Layout.legacyOuterPaddingCompensation)
                    dashboardCards(availableWidth: proxy.size.width)
                        .padding(.horizontal, Layout.legacyOuterPaddingCompensation)
                }
                .padding(.bottom, Layout.outerPadding)
            }
        }
        .background(Color.storeSurface)
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let url = viewModel.siteURLToShare {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: showCustomization) {
                    Text(Localization.edit)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.showNewCardsNotice && !viewModel.isReloadingAllData {
                                Circle()
                                    .fill(Color.storePrimary)
                                    .frame(width: Layout.dotBadgeSize)
                                    .padding(Layout.dotBadgePadding)
                                    .offset(Layout.dotBadgeOffset)
                            }
                        }
                }
                .accessibilityIdentifier("dashboard-edit-button")
                .disabled(viewModel.isReloadingAllData)
            }
        }
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .onReceive(ServiceLocator.stores.site) { currentSite in
            self.currentSite = currentSite
        }
        .onReceive(storePlanSynchronizer.planStatePublisher.removeDuplicates()) { state in
            storePlanState = state
        }
        .onReceive(connectivityObserver.statusPublisher) { status in
            connectivityStatus = status
        }
        .refreshable {
            await viewModel.onPullToRefresh()
        }
        .notice($viewModel.notice)
        .safeAreaInset(edge: .bottom) {
            jetpackBenefitBanner
                .renderedIf(shouldShowJetpackBenefitsBanner)

            storePlanBanner
                .renderedIf(connectivityStatus != .notReachable)

            OfflineBannerViewRepresentable()
                .frame(height: OfflineBannerView.height)
                .renderedIf(connectivityStatus == .notReachable)
        }
        .sheet(item: $viewModel.justInTimeMessagesWebViewModel) { webViewModel in
            WebViewSheet(viewModel: webViewModel) {
                viewModel.justInTimeMessagesWebViewModel = nil
                viewModel.maybeSyncAnnouncementsAfterWebViewDismissed()
            }
        }
        .sheet(isPresented: $viewModel.showingCustomization, onDismiss: viewModel.handleCustomizationDismissal) {
            DashboardCustomizationView(viewModel: DashboardCustomizationViewModel(
                allCards: viewModel.availableCards,
                inactiveCards: viewModel.unavailableCards,
                onSave: viewModel.didCustomizeDashboardCards
            ))
        }
        .sheet(isPresented: $viewModel.showingInAppFeedbackSurvey) {
            Survey(source: .inAppFeedback)
        }
        .sheet(isPresented: $viewModel.showingTapToPayAwarenessMoment) {
            TapToPayAwarenessMomentView()
        }
        .storeSheet(isPresented: $viewModel.showingAnalyticsImportUpdateModeInfo, sizing: .fitContent) {
            StoreAnalyticsUpdateModeSheet(viewModel: viewModel.makeAnalyticsUpdateModeBottomSheetViewModel())
        }
        .onAppear(perform: handleAppearance)
    }
}

private extension StoreDashboardView {
    var shouldShowJetpackBenefitsBanner: Bool {
        let isJetpackCPSite = currentSite?.isJetpackCPConnected == true
        let isNonJetpackSite = currentSite?.isNonJetpackSite == true
        return (isJetpackCPSite || isNonJetpackSite) &&
            viewModel.isSiteEligibleToInstallJetpack &&
            viewModel.jetpackBannerVisibleFromAppSettings &&
            !viewModel.isSelfDrivenPushNotificationRegistered &&
            !viewModel.shouldSuggestWPComConnection &&
            !viewModel.dismissedWPComConnectionSuggestion &&
            !dismissedJetpackBenefitBanner
    }

    @ViewBuilder
    func dashboardCards(availableWidth: CGFloat) -> some View {
        if shouldDisplayDashboardCardsInTwoColumns(availableWidth: availableWidth) {
            // Legacy cards own a 16-point horizontal inset. Compensate between columns so
            // their visible surfaces retain the design-system's 16-point column gap.
            HStack(alignment: .top, spacing: Layout.legacyColumnSpacingCompensation) {
                dashboardCardList(with: viewModel.showOnDashboardFirstColumn)
                dashboardCardList(with: viewModel.showOnDashboardSecondColumn)
            }
        } else {
            dashboardCardList(with: viewModel.showOnDashboardCards)
        }
    }

    func shouldDisplayDashboardCardsInTwoColumns(availableWidth: CGFloat) -> Bool {
        let hasRegularWidth: Bool
        if #available(iOS 26.0, *) {
            hasRegularWidth = availableWidth >= NarrowWindowLayout.compactLayoutThreshold
        } else {
            hasRegularWidth = horizontalSizeClass == .regular
        }

        return hasRegularWidth &&
            !dynamicTypeSize.isAccessibilitySize &&
            viewModel.showOnDashboardSecondColumn.isNotEmpty
    }

    @ViewBuilder
    func dashboardCardList(with items: [DashboardCard]) -> some View {
        VStack(spacing: Layout.cardSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.hashValue) { _, card in
                dashboardCard(for: card)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func dashboardCard(for card: DashboardCard) -> some View {
        switch card.type {
        case .onboarding:
            StoreOnboardingView(
                viewModel: viewModel.storeOnboardingViewModel,
                onTaskTapped: handleOnboardingTaskTap,
                onViewAllTapped: handleViewAllOnboardingTasksTap
            )
        case .blaze:
            BlazeCampaignDashboardView(
                viewModel: viewModel.blazeCampaignDashboardViewModel,
                showAllCampaignsTapped: actions.showAllBlazeCampaignsTapped,
                createCampaignTapped: actions.createBlazeCampaignTapped
            )
        case .performance:
            StorePerformanceDashboardCard(
                viewModel: viewModel.storePerformanceViewModel,
                onCustomRangeRedactedViewTap: { actions.customRangeRedactedViewTapped?() },
                onViewAllAnalytics: { actions.viewAllAnalyticsTapped?($0, $1, $2) },
                onAnalyticsImportUpdateModeInfoTapped: viewModel.showAnalyticsImportUpdateModeInfo
            )
            .padding(.horizontal, StorePadding.p5)
        case .topPerformers:
            StoreTopPerformersDashboardCard(
                viewModel: viewModel.topPerformersViewModel,
                onViewAllAnalytics: { actions.viewAllAnalyticsTapped?($0, $1, $2) },
                onAnalyticsImportUpdateModeInfoTapped: viewModel.showAnalyticsImportUpdateModeInfo
            )
            .padding(.horizontal, StorePadding.p5)
        case .inbox:
            InboxDashboardCard(
                viewModel: viewModel.inboxViewModel,
                onShowAllInboxMessages: { actions.showAllInboxMessagesTapped?() }
            )
        case .reviews:
            ReviewsDashboardCard(
                viewModel: viewModel.reviewsViewModel,
                onViewAllReviews: { actions.viewAllReviewsTapped?() },
                onViewReviewDetail: { actions.reviewDetailTapped?($0) }
            )
        case .coupons:
            MostActiveCouponsCard(
                viewModel: viewModel.mostActiveCouponsViewModel,
                onViewAllCoupons: { actions.viewAllCouponsTapped?() },
                onViewCouponDetail: { actions.couponDetailTapped?($0) }
            )
        case .stock:
            ProductStockDashboardCard(viewModel: viewModel.productStockCardViewModel)
        case .lastOrders:
            LastOrdersDashboardCard(
                viewModel: viewModel.lastOrdersCardViewModel,
                onViewAllOrders: { actions.viewAllOrdersTapped?() },
                onViewOrderDetail: { actions.orderDetailTapped?($0) }
            )
        case .googleAds:
            GoogleAdsDashboardCard(
                viewModel: viewModel.googleAdsDashboardCardViewModel,
                onCreateNewCampaign: { actions.createGoogleAdsCampaignTapped?() },
                onShowAllCampaigns: { actions.showAllGoogleAdsCampaignsTapped?() }
            )
        case .inAppFeedback:
            InAppFeedbackCardView(viewModel: viewModel.inAppFeedbackCardViewModel)
                .padding(.horizontal, LegacyLayout.padding)
        case .newCardsNotice:
            newCardsNoticeCard
        case .shareStore:
            shareStoreCard
        case .connectWPCom:
            connectWPComCard
        case .aiAssistant:
            aiAssistantCard
        }
    }

    @ViewBuilder
    var aiAssistantCard: some View {
        if let currentSite {
            AIAssistantDashboardCard(site: currentSite)
                .padding(.horizontal, LegacyLayout.padding)
        }
    }

    var shareStoreCard: some View {
        VStack(spacing: .zero) {
            Image(uiImage: .launchImage)
                .padding(.top, LegacyLayout.imagePadding)
                .padding(.bottom, LegacyLayout.elementPadding)

            Text(Localization.ShareStoreCard.title)
                .headlineStyle()
                .multilineTextAlignment(.center)

            Text(Localization.ShareStoreCard.subtitle)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, LegacyLayout.elementPadding)
                .padding(.top, LegacyLayout.textPadding)

            if let url = viewModel.siteURLToShare {
                ShareLink(item: url) {
                    Text(Localization.ShareStoreCard.shareButtonLabel)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, LegacyLayout.elementPadding)
                .padding(.top, LegacyLayout.elementPadding)
            }
        }
        .padding(.bottom, LegacyLayout.elementPadding)
        .overlay {
            RoundedRectangle(cornerRadius: LegacyLayout.cornerRadius)
                .stroke(Color(.border), lineWidth: 1)
        }
        .padding(.horizontal, LegacyLayout.padding)
    }

    var connectWPComCard: some View {
        ConnectWPComCard(
            setupAction: { actions.connectWPComSetupTapped?() },
            hideAction: viewModel.hideWPComConnectionSuggestion
        )
        .onAppear(perform: viewModel.onConnectWPComCardAppear)
    }

    var newCardsNoticeCard: some View {
        VStack(spacing: LegacyLayout.padding) {
            Text(Localization.NewCardsNoticeCard.title)
                .headlineStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, LegacyLayout.elementPadding)
                .padding(.top, LegacyLayout.padding)

            Text(Localization.NewCardsNoticeCard.subtitle)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, LegacyLayout.elementPadding)

            Button(Localization.NewCardsNoticeCard.addSectionsButtonText, action: showNewSections)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, LegacyLayout.elementPadding)
                .padding(.bottom, LegacyLayout.elementPadding)
        }
        .background(Color(.listForeground(modal: false)))
        .clipShape(.rect(cornerRadius: LegacyLayout.cornerRadius))
        .padding(.horizontal, LegacyLayout.padding)
    }

    var jetpackBenefitBanner: some View {
        JetpackBenefitsBanner(tapAction: handleJetpackBenefitTap, dismissAction: dismissJetpackBenefitBanner)
    }

    @ViewBuilder
    var storePlanBanner: some View {
        if case .loaded(let plan) = storePlanState {
            if plan.isFreeTrial {
                StorePlanBanner(text: FreeTrialBannerViewModel(sitePlan: plan).message)
            } else if plan.isFreePlan && currentSite?.wasEcommerceTrial == true {
                StorePlanBanner(text: Localization.expiredPlan)
            }
        }
    }

    @ViewBuilder
    var featureAnnouncementCard: some View {
        if viewModel.shouldShowAnnouncementBanner,
           let announcementViewModel = viewModel.announcementViewModel {
            FeatureAnnouncementCardView(
                viewModel: announcementViewModel,
                dismiss: { viewModel.announcementViewModel = nil },
                callToAction: {
                    if announcementViewModel is FeatureAnnouncementCardViewModel {
                        viewModel.handleClientSideBannerCTATapped()
                    }
                }
            )
            .background(Color(.listForeground(modal: false)))
            .clipShape(.rect(cornerRadius: LegacyLayout.cornerRadius))
            .padding(.horizontal, LegacyLayout.padding)
        }
    }

    func showCustomization() {
        ServiceLocator.analytics.track(
            event: .DynamicDashboard.editLayoutButtonTapped(isNewCardAvailable: viewModel.showNewCardsNotice)
        )
        viewModel.showCustomizationScreen()
    }

    func showNewSections() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardAddNewSectionsTapped())
        viewModel.showCustomizationScreen()
    }

    func handleOnboardingTaskTap(_ task: StoreOnboardingTask) {
        guard let currentSite else { return }
        actions.onboardingTaskTapped?(currentSite, task)
    }

    func handleViewAllOnboardingTasksTap(_ tasks: [StoreOnboardingTaskViewModel]) {
        guard let currentSite else { return }
        actions.viewAllOnboardingTasksTapped?(currentSite, tasks)
    }

    func handleJetpackBenefitTap() {
        ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .tapped))
        guard let currentSite else { return }
        actions.jetpackBenefitsBannerTapped?(currentSite)
    }

    func dismissJetpackBenefitBanner() {
        ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .dismissed))
        viewModel.saveJetpackBenefitBannerDismissedTime()
        dismissedJetpackBenefitBanner = true
    }

    func handleAppearance() {
        Task {
            await viewModel.onViewAppear()
        }
    }
}

private extension StoreDashboardView {
    enum Layout {
        static let outerPadding = StoreSpacing.s7
        static let cardSpacing = StoreSpacing.s7
        static let legacyOuterPaddingCompensation = StoreSpacing.s3
        static let legacyColumnSpacingCompensation = -StoreSpacing.s5
        static let dotBadgePadding = EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 2)
        static let dotBadgeSize: CGFloat = 6
        static let dotBadgeOffset = CGSize(width: 7, height: -7)
    }

    enum LegacyLayout {
        static let padding: CGFloat = 16
        static let elementPadding: CGFloat = 24
        static let imagePadding: CGFloat = 40
        static let textPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "dashboardView.title",
            value: "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
        static let expiredPlan = NSLocalizedString(
            "dashboardView.storePlanBanner.expired",
            value: "Your site plan has ended.",
            comment: "Title on the banner when the site's WooExpress plan has expired"
        )
        static let edit = NSLocalizedString(
            "dashboardView.edit",
            value: "Edit",
            comment: "Title of the button to edit the layout of the Dashboard screen."
        )

        enum ShareStoreCard {
            static let title = NSLocalizedString(
                "dashboardView.shareStoreCard.title",
                value: "Get the word out!",
                comment: "Title of the Share Your Store card"
            )
            static let subtitle = NSLocalizedString(
                "dashboardView.shareStoreCard.subtitle",
                value: "Use email or social media to spread the word about your store.",
                comment: "Subtitle of the Share Your Store card"
            )
            static let shareButtonLabel = NSLocalizedString(
                "dashboardView.shareStoreCard.shareButtonLabel",
                value: "Share Your Store",
                comment: "Label of the button to share the store"
            )
        }

        enum NewCardsNoticeCard {
            static let title = NSLocalizedString(
                "dashboardView.newCardsNoticeCard.title",
                value: "Looking for more insights?",
                comment: "Title of the New Cards Notice card"
            )
            static let subtitle = NSLocalizedString(
                "dashboardView.newCardsNoticeCard.subtitle",
                value: "Add new sections to customize your store management experience",
                comment: "Subtitle of the New Cards Notice card"
            )
            static let addSectionsButtonText = NSLocalizedString(
                "dashboardView.newCardsNoticeCard.addSectionsButtonText",
                value: "Add New Sections",
                comment: "Label of the button to add sections"
            )
        }
    }
}
