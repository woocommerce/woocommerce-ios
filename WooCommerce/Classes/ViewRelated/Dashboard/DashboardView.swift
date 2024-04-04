import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// View for the dashboard screen
///
struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    @State private var currentSite: Site?

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

    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    init(viewModel: DashboardViewModel,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.viewModel = viewModel
        self.usageTracksEventEmitter = usageTracksEventEmitter
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
                    ViewControllerContainer(
                        StoreStatsAndTopPerformersViewController(siteID: viewModel.siteID,
                                                                 dashboardViewModel: viewModel,
                                                                 usageTracksEventEmitter: usageTracksEventEmitter)
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ViewControllerContainer(DeprecatedDashboardStatsViewController())
                        .frame(maxHeight: .infinity)
                }
            case .topPerformers:
                EmptyView() // TODO-12403: handle this after separating stats and top performers
            }
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
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(siteID: 123), usageTracksEventEmitter: .init())
}
