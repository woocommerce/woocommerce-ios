import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask
import struct Yosemite.Coupon
import struct Yosemite.Order

/// View for the dashboard screen
///
struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var currentSite: Site?
    @State private var dismissedJetpackBenefitBanner = false
    @State private var showingSupportForm = false
    @State private var troubleshootURL: URL?
    @State private var storePlanState: StorePlanSyncState = .loading
    @State private var connectivityStatus: ConnectivityStatus = .notReachable

    /// Set externally in the hosting controller.
    var onboardingTaskTapped: ((Site, StoreOnboardingTask) -> Void)?
    /// Set externally in the hosting controller.
    var viewAllOnboardingTasksTapped: ((Site) -> Void)?
    /// Set externally in the hosting controller.
    var onboardingShareFeedbackAction: (() -> Void)?

    /// Set externally in the hosting controller.
    var showAllBlazeCampaignsTapped: (() -> Void)?
    /// Set externally in the hosting controller.
    var createBlazeCampaignTapped: ((_ productID: Int64?) -> Void)?

    /// Set externally in the hosting controller.
    var jetpackBenefitsBannerTapped: ((Site) -> Void)?

    /// Set externally in the hosting controller.
    var onCustomRangeRedactedViewTap: (() -> Void)?
    /// Set externally in the hosting controller.
    var onViewAllAnalytics: ((_ siteID: Int64,
                              _ timeZone: TimeZone,
                              _ timeRange: StatsTimeRangeV4) -> Void)?
    /// Set externally in the hosting controller.
    var onViewAllCoupons: (() -> Void)?

    /// Set externally in the hosting controller.
    var onViewCouponDetail: ((_ coupon: Coupon) -> Void)?

    /// Set externally in the hosting controller.
    var onShowAllInboxMessages: (() -> Void)?

    /// Set externally in the hosting controller.
    var onViewAllOrders: (() -> Void)?

    /// Set externally in the hosting controller.
    var onViewOrderDetail: ((_ order: Order) -> Void)?

    /// Set externally in the hosting controller.
    var onViewReviewDetail: ((_ review: ReviewViewModel) -> Void)?

    /// Set externally in the hosting controller.
    var onViewAllReviews: (() -> Void)?

    /// Set externally in the hosting controller.
    var onCreateNewGoogleAdsCampaign: (() -> Void)?
    /// Set externally in the hosting controller.
    var onShowAllGoogleAdsCampaigns: (() -> Void)?

    private let storePlanSynchronizer = ServiceLocator.storePlanSynchronizer
    private let connectivityObserver = ServiceLocator.connectivityObserver

    private var shouldShowJetpackBenefitsBanner: Bool {
        let isJetpackCPSite = currentSite?.isJetpackCPConnected == true
        let isNonJetpackSite = currentSite?.isNonJetpackSite == true
        return (isJetpackCPSite || isNonJetpackSite) &&
            viewModel.jetpackBannerVisibleFromAppSettings &&
            dismissedJetpackBenefitBanner == false
    }

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            // Store title
            Text(currentSite?.name ?? Localization.title)
                .subheadlineStyle()
                .padding([.horizontal, .bottom], Layout.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .renderedIf(verticalSizeClass == .regular)

            // Feature announcement if any.
            featureAnnouncementCard

            // Card views
            dashboardCards
                .padding(.bottom, Layout.padding)
        }
        .background(Color(.listBackground))
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
                Button(action: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.editLayoutButtonTapped(isNewCardAvailable: viewModel.showNewCardsNotice))
                    viewModel.showCustomizationScreen()
                }, label: {
                    Text(Localization.edit)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.showNewCardsNotice &&
                                !viewModel.isReloadingAllData {
                                Circle()
                                    .fill(Color(.accent))
                                    .frame(width: Layout.dotBadgeSize)
                                    .padding(Layout.dotBadgePadding)
                                    .offset(Layout.dotBadgeOffset)
                            }
                        }
                })
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
            viewModel.onPullToRefresh()
        }
        .safeAreaInset(edge: .bottom) {
            jetpackBenefitBanner
                .renderedIf(shouldShowJetpackBenefitsBanner)

            storePlanBanner
                .renderedIf(connectivityStatus != .notReachable)
        }
        .sheet(isPresented: $showingSupportForm) {
            supportForm
        }
        .safariSheet(url: $troubleshootURL)
        .sheet(item: $viewModel.justInTimeMessagesWebViewModel) { webViewModel in
            WebViewSheet(viewModel: webViewModel) {
                viewModel.justInTimeMessagesWebViewModel = nil
                viewModel.maybeSyncAnnouncementsAfterWebViewDismissed()
            }
        }
        .sheet(isPresented: $viewModel.showingCustomization,
               onDismiss: {
            viewModel.handleCustomizationDismissal()
        }) {
            DashboardCustomizationView(viewModel: DashboardCustomizationViewModel(
                allCards: viewModel.availableCards,
                inactiveCards: viewModel.unavailableCards,
                onSave: { viewModel.didCustomizeDashboardCards($0) }
            ))
        }
        .sheet(isPresented: $viewModel.showingInAppFeedbackSurvey) {
            Survey(source: .inAppFeedback)
        }
        .onAppear {
            Task {
                await viewModel.onViewAppear()
            }
        }
    }
}

// MARK: Private helpers
//
private extension DashboardView {
    @ViewBuilder
    var dashboardCards: some View {
        VStack(spacing: Layout.padding) {
            ForEach(Array(viewModel.showOnDashboardCards.enumerated()), id: \.element.hashValue) { index, card in
                VStack(spacing: Layout.padding) {
                    switch card.type {
                    case .onboarding:
                        StoreOnboardingView(viewModel: viewModel.storeOnboardingViewModel,
                                            onTaskTapped: { task in
                            guard let currentSite else { return }
                            onboardingTaskTapped?(currentSite, task)
                        }, onViewAllTapped: {
                            guard let currentSite else { return }
                            viewAllOnboardingTasksTapped?(currentSite)
                        }, shareFeedbackAction: {
                            onboardingShareFeedbackAction?()
                        })
                    case .blaze:
                        BlazeCampaignDashboardView(viewModel: viewModel.blazeCampaignDashboardViewModel,
                                                   showAllCampaignsTapped: showAllBlazeCampaignsTapped,
                                                   createCampaignTapped: createBlazeCampaignTapped)
                    case .performance:
                        StorePerformanceView(viewModel: viewModel.storePerformanceViewModel,
                                             onCustomRangeRedactedViewTap: {
                            onCustomRangeRedactedViewTap?()
                        }, onViewAllAnalytics: { siteID, siteTimeZone, timeRange in
                            onViewAllAnalytics?(siteID, siteTimeZone, timeRange)
                        })
                    case .topPerformers:
                        TopPerformersDashboardView(viewModel: viewModel.topPerformersViewModel,
                                                   onViewAllAnalytics: { siteID, siteTimeZone, timeRange in
                            onViewAllAnalytics?(siteID, siteTimeZone, timeRange)
                        })
                    case .inbox:
                        InboxDashboardCard(viewModel: viewModel.inboxViewModel) {
                            onShowAllInboxMessages?()
                        }
                    case .reviews:
                        ReviewsDashboardCard(viewModel: viewModel.reviewsViewModel,
                                             onViewAllReviews: {
                            onViewAllReviews?()
                        }, onViewReviewDetail: { review in
                            onViewReviewDetail?(review)
                        })
                    case .coupons:
                        MostActiveCouponsCard(viewModel: viewModel.mostActiveCouponsViewModel,
                                              onViewAllCoupons: {
                            onViewAllCoupons?()
                        }, onViewCouponDetail: { coupon in
                            onViewCouponDetail?(coupon)
                        })
                    case .stock:
                        ProductStockDashboardCard(viewModel: viewModel.productStockCardViewModel)
                    case .lastOrders:
                        LastOrdersDashboardCard(viewModel: viewModel.lastOrdersCardViewModel) {
                            onViewAllOrders?()
                        } onViewOrderDetail: { order in
                            onViewOrderDetail?(order)
                        }
                    case .googleAds:
                        GoogleAdsDashboardCard(viewModel: viewModel.googleAdsDashboardCardViewModel, onCreateNewCampaign: {
                            onCreateNewGoogleAdsCampaign?()
                        }, onShowAllCampaigns: {
                            onShowAllGoogleAdsCampaigns?()
                        })
                    }

                    // Append feedback card after the first card
                    if index == 0 && viewModel.isInAppFeedbackCardVisible {
                        feedbackCard
                    }
                }
            }

            if viewModel.showNewCardsNotice && !viewModel.isReloadingAllData {
                newCardsNoticeCard
            }

            if !viewModel.hasOrders && !viewModel.isReloadingAllData {
                shareStoreCard
            }
        }
    }

    var feedbackCard: some View {
        InAppFeedbackCardView(viewModel: viewModel.inAppFeedbackCardViewModel)
            .padding(.horizontal, Layout.padding)
    }

    var shareStoreCard: some View {
        VStack(spacing: .zero) {
            Image(uiImage: .blazeSuccessImage)
                .padding(.top, Layout.imagePadding)
                .padding(.bottom, Layout.elementPadding)

            Text(Localization.ShareStoreCard.title)
                .headlineStyle()
                .multilineTextAlignment(.center)

            Text(Localization.ShareStoreCard.subtitle)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.elementPadding)
                .padding(.top, Layout.textPadding)

            if let url = viewModel.siteURLToShare {
                ShareLink(item: url) {
                    Text(Localization.ShareStoreCard.shareButtonLabel)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.elementPadding)
                .padding(.top, Layout.elementPadding)
            }
        }
        .padding(.bottom, Layout.elementPadding)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.border), lineWidth: 1)
        )
        .padding(.horizontal, Layout.padding)
    }

    var newCardsNoticeCard: some View {
        VStack(spacing: Layout.padding) {
            Text(Localization.NewCardsNoticeCard.title)
                .headlineStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.elementPadding)
                .padding(.top, Layout.padding)

            Text(Localization.NewCardsNoticeCard.subtitle)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.elementPadding)

            Button(Localization.NewCardsNoticeCard.addSectionsButtonText) {
                ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardAddNewSectionsTapped())

                viewModel.showCustomizationScreen()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.elementPadding)
            .padding(.bottom, Layout.elementPadding)
        }
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }

    var jetpackBenefitBanner: some View {
        JetpackBenefitsBanner(tapAction: {
            ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .tapped))
            guard let currentSite else { return }
            jetpackBenefitsBannerTapped?(currentSite)
        }, dismissAction: {
            ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .dismissed))
            viewModel.saveJetpackBenefitBannerDismissedTime()
            dismissedJetpackBenefitBanner = true
        })
    }

    var supportForm: some View {
        NavigationStack {
            SupportForm(isPresented: .constant(true), viewModel: .init())
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.done) {
                            showingSupportForm = false
                        }
                    }
                }
        }
    }

    @ViewBuilder
    var storePlanBanner: some View {
        if case .loaded(let plan) = storePlanState {
            if plan.isFreeTrial {
                let bannerViewModel = FreeTrialBannerViewModel(sitePlan: plan)
                StorePlanBanner(text: bannerViewModel.message)
            } else if plan.isFreePlan && currentSite?.wasEcommerceTrial == true {
                StorePlanBanner(text: Localization.expiredPlan)
            }
        }
    }

    @ViewBuilder
    var featureAnnouncementCard: some View {
        if let announcementViewModel = viewModel.announcementViewModel,
           viewModel.dashboardCards.contains(where: { $0.type == .onboarding }) == false {
            FeatureAnnouncementCardView(viewModel: announcementViewModel, dismiss: {
                viewModel.announcementViewModel = nil
            })
            .background(Color(.listForeground(modal: false)))
        }
    }
}

// MARK: Subtypes
private extension DashboardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let elementPadding: CGFloat = 24
        static let imagePadding: CGFloat = 40
        static let textPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
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
        static let done = NSLocalizedString(
            "dashboardView.supportForm.done",
            value: "Done",
            comment: "Button to dismiss the support form from the Blaze confirm payment view screen."
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
                value: "Use email or social media to spread the word about your store",
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

#Preview {
    DashboardView(viewModel: DashboardViewModel(siteID: 123, usageTracksEventEmitter: .init()))
}
