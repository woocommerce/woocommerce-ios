import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// View for the dashboard screen
///
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var currentSite: Site?

    /// Set externally in the hosting controller.
    var onboardingTaskTapped: ((Site, StoreOnboardingTask) -> Void)?
    /// Set externally in the hosting controller.
    var viewAllOnboardingTasksTapped: ((Site) -> Void)?
    /// Set externally in the hosting controller.
    var onboardingShareFeedbackAction: (() -> Void)?

    init(viewModel: DashboardViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            // Store title
            Text(currentSite?.name ?? Localization.title)
                .secondaryBodyStyle()
                .padding(.horizontal, Layout.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Card views
            dashboardCards
        }
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
        ForEach(viewModel.dashboardCards) { card in
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
            case .blaze, .stats, .topPerformers:
                EmptyView()
            }
        }
    }
}

// MARK: Subtypes
private extension DashboardView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
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
    DashboardView(viewModel: DashboardViewModel(siteID: 123))
}
