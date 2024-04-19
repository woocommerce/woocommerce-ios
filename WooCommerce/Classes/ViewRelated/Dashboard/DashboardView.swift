import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// View for the dashboard screen
///
struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var currentSite: Site?
    @State private var dismissedJetpackBenefitBanner = false
    @State private var showingSupportForm = false
    @State private var showingCustomization = false
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
                .background(Color(.listForeground(modal: false)))
                .renderedIf(verticalSizeClass == .regular)

            // Error banner
            if let error = viewModel.statSyncingError {
                errorTopBanner(for: error)
            }

            // Feature announcement if any.
            featureAnnouncementCard

            // Card views
            dashboardCards(showShareCard: !viewModel.hasOrders)
                .padding(.vertical, Layout.padding)
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
                Button {
                    showingCustomization = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
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
            Task { @MainActor in
                ServiceLocator.analytics.track(.dashboardPulledToRefresh)
                await viewModel.reloadAllData()
            }
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
        .sheet(isPresented: $showingCustomization) {
            DashboardCustomizationView(viewModel: DashboardCustomizationViewModel(
                allCards: viewModel.dashboardCards,
                inactiveCards: viewModel.unavailableDashboardCards,
                onSave: { viewModel.didCustomizeDashboardCards($0) }
            ))
        }
    }
}

// MARK: Private helpers
//
private extension DashboardView {
    @ViewBuilder
    func dashboardCards(showShareCard: Bool) -> some View {
        VStack(spacing: Layout.padding) {
            ForEach(viewModel.dashboardCards, id: \.hashValue) { card in
                if card.enabled {
                    switch card.type {
                    case .onboarding:
                        StoreOnboardingView(canHideCard: viewModel.canHideMoreDashboardCards,
                                            viewModel: viewModel.storeOnboardingViewModel,
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
                        BlazeCampaignDashboardView(canHideCard: viewModel.canHideMoreDashboardCards,
                                                   viewModel: viewModel.blazeCampaignDashboardViewModel,
                                                   showAllCampaignsTapped: showAllBlazeCampaignsTapped,
                                                   createCampaignTapped: createBlazeCampaignTapped)
                    case .performance:
                        StorePerformanceView(canHideCard: viewModel.canHideMoreDashboardCards,
                                             viewModel: viewModel.storePerformanceViewModel,
                                             onCustomRangeRedactedViewTap: {
                            onCustomRangeRedactedViewTap?()
                        }, onViewAllAnalytics: { siteID, siteTimeZone, timeRange in
                            onViewAllAnalytics?(siteID, siteTimeZone, timeRange)
                        })
                    case .topPerformers:
                        TopPerformersDashboardView(canHideCard: viewModel.canHideMoreDashboardCards,
                                                   viewModel: viewModel.topPerformersViewModel,
                                                   onViewAllAnalytics: { siteID, siteTimeZone, timeRange in
                            onViewAllAnalytics?(siteID, siteTimeZone, timeRange)
                        })
                    }
                }
            }

            if showShareCard {
                shareStoreCard
            }
        }
    }

    var shareStoreCard: some View {
        VStack {
            Image(uiImage: .blazeSuccessImage)
                .padding(Layout.imagePadding)

            Text(Localization.ShareStoreCard.title)
                .headlineStyle()
                .multilineTextAlignment(.center)

            Text(Localization.ShareStoreCard.subtitle)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.elementPadding)
                .padding(.top, Layout.textPadding)

            Button(Localization.ShareStoreCard.shareButtonLabel) {
                // TODO
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.elementPadding)
            .padding(.vertical, Layout.elementPadding)
        }
        .background(Color(.clear))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.border), lineWidth: 1)
        )
        .padding(.vertical, Layout.padding)
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

    func errorTopBanner(for error: Error) -> some View {
        ErrorTopBanner(error: error, onTroubleshootButtonPressed: {
            troubleshootURL = ErrorTopBannerFactory.troubleshootUrl(for: error)
        }, onContactSupportButtonPressed: {
            showingSupportForm = true
        })
        .background(Color(.listForeground(modal: false)))
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
        static let imagePadding: CGFloat = 32
        static let textPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 8
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
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(siteID: 123, usageTracksEventEmitter: .init()))
}
