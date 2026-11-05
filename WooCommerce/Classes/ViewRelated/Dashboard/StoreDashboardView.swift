import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask
import enum WooFoundation.ConnectivityStatus

/// Design-system dashboard shown while the dashboard design-system feature flag is enabled.
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
                        .padding(.horizontal, Layout.outerPadding)
                    dashboardCards(availableWidth: proxy.size.width)
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

            storePlanNotice
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
    var designSystemDashboardCards: [DashboardCard] {
        viewModel.showOnDashboardCards.cardsForStoreDashboard
    }

    var designSystemFirstColumn: [DashboardCard] {
        designSystemDashboardCards.enumerated().compactMap { index, card in
            index.isMultiple(of: 2) ? card : nil
        }
    }

    var designSystemSecondColumn: [DashboardCard] {
        designSystemDashboardCards.enumerated().compactMap { index, card in
            index.isMultiple(of: 2) ? nil : card
        }
    }

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
            HStack(alignment: .top, spacing: Layout.columnSpacing) {
                dashboardCardList(with: designSystemFirstColumn)
                dashboardCardList(with: designSystemSecondColumn)
            }
            .padding(.horizontal, Layout.outerPadding)
        } else {
            dashboardCardList(with: designSystemDashboardCards)
                .padding(.horizontal, Layout.outerPadding)
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
            designSystemSecondColumn.isNotEmpty
    }

    @ViewBuilder
    func dashboardCardList(with items: [DashboardCard]) -> some View {
        VStack(spacing: Layout.cardSpacing) {
            ForEach(items, id: \.type) { card in
                dashboardCard(for: card)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func dashboardCard(for card: DashboardCard) -> some View {
        switch card.type {
        case .onboarding:
            StoreOnboardingDashboardCard(
                viewModel: viewModel.storeOnboardingViewModel,
                onTaskTapped: handleOnboardingTaskTap,
                onViewAllTapped: handleViewAllOnboardingTasksTap
            )
        case .blaze:
            StoreBlazeCampaignDashboardView(
                viewModel: viewModel.blazeCampaignDashboardViewModel,
                showAllCampaignsTapped: actions.showAllBlazeCampaignsTapped,
                createCampaignTapped: actions.createBlazeCampaignTapped
            )
            .padding(.horizontal, StorePadding.p5)
        case .performance:
            StorePerformanceDashboardCard(
                viewModel: viewModel.storePerformanceViewModel,
                onCustomRangeRedactedViewTap: { actions.customRangeRedactedViewTapped?() },
                onViewAllAnalytics: { actions.viewAllAnalyticsTapped?($0, $1, $2) },
                onAnalyticsImportUpdateModeInfoTapped: viewModel.showAnalyticsImportUpdateModeInfo
            )
        case .topPerformers:
            StoreTopPerformersDashboardCard(
                viewModel: viewModel.topPerformersViewModel,
                onViewAllAnalytics: { actions.viewAllAnalyticsTapped?($0, $1, $2) },
                onAnalyticsImportUpdateModeInfoTapped: viewModel.showAnalyticsImportUpdateModeInfo
            )
        case .inbox:
            StoreInboxDashboardCard(
                viewModel: viewModel.inboxViewModel,
                onShowAllInboxMessages: { actions.showAllInboxMessagesTapped?() }
            )
            .padding(.horizontal, StorePadding.p5)
        case .reviews:
            StoreReviewsDashboardCard(
                viewModel: viewModel.reviewsViewModel,
                onViewAllReviews: { actions.viewAllReviewsTapped?() },
                onViewReviewDetail: { actions.reviewDetailTapped?($0) }
            )
            .padding(.horizontal, StorePadding.p5)
        case .coupons:
            StoreMostActiveCouponsCard(
                viewModel: viewModel.mostActiveCouponsViewModel,
                onViewAllCoupons: { actions.viewAllCouponsTapped?() },
                onViewCouponDetail: { actions.couponDetailTapped?($0) }
            )
        case .stock:
            StoreProductStockDashboardCard(viewModel: viewModel.productStockCardViewModel)
        case .lastOrders:
            StoreLastOrdersDashboardCard(
                viewModel: viewModel.lastOrdersCardViewModel,
                onViewAllOrders: { actions.viewAllOrdersTapped?() },
                onViewOrderDetail: { actions.orderDetailTapped?($0) }
            )
        case .googleAds:
            StoreGoogleAdsDashboardCard(
                viewModel: viewModel.googleAdsDashboardCardViewModel,
                onCreateNewCampaign: { actions.createGoogleAdsCampaignTapped?() },
                onShowAllCampaigns: { actions.showAllGoogleAdsCampaignsTapped?() }
            )
            .padding(.horizontal, StorePadding.p5)
        case .inAppFeedback:
            StoreDashboardFeedbackCard(viewModel: viewModel.inAppFeedbackCardViewModel)
        case .newCardsNotice:
            StoreDashboardNewCardsNotice(showCustomization: showNewSections)
        case .shareStore:
            StoreDashboardShareStoreCard(url: viewModel.siteURLToShare)
        case .connectWPCom:
            StoreConnectWPComCard(
                setupAction: { actions.connectWPComSetupTapped?() },
                hideAction: viewModel.hideWPComConnectionSuggestion
            )
            .onAppear(perform: viewModel.onConnectWPComCardAppear)
        case .aiAssistant:
            aiAssistantCard
        }
    }

    @ViewBuilder
    var aiAssistantCard: some View {
        if let currentSite {
            StoreAIAssistantDashboardCard(site: currentSite)
        }
    }

    var jetpackBenefitBanner: some View {
        JetpackBenefitsBanner(tapAction: handleJetpackBenefitTap, dismissAction: dismissJetpackBenefitBanner)
    }

    @ViewBuilder
    var storePlanNotice: some View {
        if case .loaded(let plan) = storePlanState {
            if plan.isFreeTrial {
                StoreNoticeBanner(
                    FreeTrialBannerViewModel(sitePlan: plan).message,
                    tone: .info,
                    icon: StoreIcon.CircleInfo.regular
                )
                .padding(.horizontal, StorePadding.p5)
                .padding(.bottom, StorePadding.p3)
            } else if plan.isFreePlan && currentSite?.wasEcommerceTrial == true {
                StoreNoticeBanner(
                    Localization.expiredPlan,
                    tone: .info,
                    icon: StoreIcon.CircleInfo.regular
                )
                .padding(.horizontal, StorePadding.p5)
                .padding(.bottom, StorePadding.p3)
            }
        }
    }

    @ViewBuilder
    var featureAnnouncementCard: some View {
        if viewModel.shouldShowAnnouncementBanner,
           let announcementViewModel = viewModel.announcementViewModel {
            StoreDashboardFeatureAnnouncementCard(
                viewModel: announcementViewModel,
                dismiss: { viewModel.announcementViewModel = nil },
                callToAction: {
                    if announcementViewModel is FeatureAnnouncementCardViewModel {
                        viewModel.handleClientSideBannerCTATapped()
                    }
                }
            )
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
        static let columnSpacing = StoreSpacing.s5
        static let dotBadgePadding = EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 2)
        static let dotBadgeSize: CGFloat = 6
        static let dotBadgeOffset = CGSize(width: 7, height: -7)
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
    }
}
