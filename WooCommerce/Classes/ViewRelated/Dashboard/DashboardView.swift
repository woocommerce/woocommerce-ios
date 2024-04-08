import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// View for the dashboard screen
///
struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    @State private var currentSite: Site?
    @State private var dismissedJetpackBenefitBanner = false
    @State private var showingSupportForm = false
    @State private var troubleShootURL: URL?
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

    private let storeStatsAndTopPerformersViewController: StoreStatsAndTopPerformersViewController
    private let storePlanSynchronizer = ServiceLocator.storePlanSynchronizer
    private let connectivityObserver = ServiceLocator.connectivityObserver

    private var shouldShowJetpackBenefitsBanner: Bool {
        let isJetpackCPSite = currentSite?.isJetpackCPConnected == true
        let isNonJetpackSite = currentSite?.isNonJetpackSite == true
        return (isJetpackCPSite || isNonJetpackSite) &&
            viewModel.jetpackBannerVisibleFromAppSettings &&
            dismissedJetpackBenefitBanner == false
    }

    init(viewModel: DashboardViewModel,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.viewModel = viewModel
        self.storeStatsAndTopPerformersViewController = StoreStatsAndTopPerformersViewController(
            siteID: viewModel.siteID,
            dashboardViewModel: viewModel,
            usageTracksEventEmitter: usageTracksEventEmitter
        )

        storeStatsAndTopPerformersViewController.onDataReload = {
            viewModel.statSyncingError = nil
        }

        storeStatsAndTopPerformersViewController.displaySyncingError = { error in
            viewModel.statSyncingError = error
        }
    }

    var body: some View {
        ScrollView {
            // Store title
            Text(currentSite?.name ?? Localization.title)
                .subheadlineStyle()
                .padding([.horizontal, .bottom], Layout.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.listForeground(modal: false)))

            // Error banner
            if let error = viewModel.statSyncingError {
                errorTopBanner(for: error)
            }

            // Feature announcement if any.
            featureAnnouncementCard

            // Card views
            dashboardCards
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
                await storeStatsAndTopPerformersViewController.reloadData(forced: true)
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
        .safariSheet(url: $troubleShootURL)
        .sheet(item: $viewModel.justInTimeMessagesWebViewModel) { webViewModel in
            WebViewSheet(viewModel: webViewModel) {
                viewModel.justInTimeMessagesWebViewModel = nil
                viewModel.maybeSyncAnnouncementsAfterWebViewDismissed()
            }
        }
    }
}

// MARK: Private helpers
//
private extension DashboardView {
    var dashboardCards: some View {
        ForEach(viewModel.dashboardCards, id: \.self) { card in
            switch card {
            case .onboarding:
                StoreOnboardingView(viewModel: viewModel.storeOnboardingViewModel, onTaskTapped: { task in
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
            case .stats:
                if viewModel.statsVersion == .v4 {
                    ViewControllerContainer(storeStatsAndTopPerformersViewController)
                } else {
                    ViewControllerContainer(DeprecatedDashboardStatsViewController())
                }
            case .topPerformers:
                EmptyView() // TODO-12403: handle this after separating stats and top performers
            }
        }
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
            troubleShootURL = ErrorTopBannerFactory.troubleshootUrl(for: error)
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
            viewModel.dashboardCards.contains(.onboarding) == false {
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
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(siteID: 123), usageTracksEventEmitter: .init())
}
