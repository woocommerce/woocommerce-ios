import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// View for the dashboard screen
///
struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    @State private var currentSite: Site?
    @State private var dismissedJetpackBenefitBanner = false

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
    }

    var body: some View {
        ScrollView {
            // Store title
            Text(currentSite?.name ?? Localization.title)
                .subheadlineStyle()
                .padding([.horizontal, .bottom], Layout.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.listForeground(modal: false)))

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
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(siteID: 123), usageTracksEventEmitter: .init())
}
