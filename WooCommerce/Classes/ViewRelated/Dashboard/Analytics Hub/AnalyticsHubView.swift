import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {

    private let viewModel: AnalyticsHubViewModel

    /// Presents an error notice in the tab bar context after this `self` is dismissed.
    ///
    private let systemNoticePresenter: NoticePresenter

    /// Defines a notice that should be presented after `self` is dismissed.
    /// Defaults to `nil`.
    ///
    var notice: Notice?

    /// Coordinator to handle Google Ads campaign creation.
    private var googleAdsCampaignCoordinator: GoogleAdsCampaignCoordinator?

    init(siteID: Int64,
         timeZone: TimeZone,
         timeRange: StatsTimeRangeV4,
         systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.viewModel = AnalyticsHubViewModel(siteID: siteID, timeZone: timeZone, statsTimeRange: timeRange, usageTracksEventEmitter: usageTracksEventEmitter)
        self.systemNoticePresenter = systemNoticePresenter
        super.init(rootView: AnalyticsHubView(viewModel: self.viewModel))

        // Needed to pop the hosting controller from within the SwiftUI view
        rootView.dismissWithNotice = { [weak self] notice in
            self?.notice = notice
            self?.navigationController?.popViewController(animated: true)
        }

        configureGoogleAdsCard()
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Show any notice that should be presented after the underlying disappears.
        enqueuePendingNotice(notice, using: systemNoticePresenter)
    }
}

// MARK: Google Ads campaigns
private extension AnalyticsHubHostingViewController {
    func configureGoogleAdsCard() {
        rootView.onCreateNewGoogleAdsCampaign = { [weak self] in
            self?.startGoogleAdsCampaignCreation()
        }
    }

    /// Initializes a `GoogleAdsCampaignCoordinator` to handle campaign creation.
    ///
    func startGoogleAdsCampaignCreation() {
        guard let site = viewModel.stores.sessionManager.defaultSite,
              let navigationController else {
            return
        }

        let coordinator = GoogleAdsCampaignCoordinator(
            siteID: viewModel.siteID,
            siteAdminURL: site.adminURLWithFallback()?.absoluteString ?? site.adminURL,
            source: .analyticsHub,
            shouldStartCampaignCreation: true,
            shouldAuthenticateAdminPage: viewModel.stores.shouldAuthenticateAdminPage(for: site),
            navigationController: navigationController,
            onCompletion: { [weak self] createdNewCampaign in
                if createdNewCampaign {
                    Task { @MainActor in
                        await self?.viewModel.googleCampaignsCard.onGoogleCampaignCreated()
                    }
                }
            }
        )
        coordinator.start()
        googleAdsCampaignCoordinator = coordinator

        viewModel.analytics.track(event: .GoogleAds.entryPointTapped(
            source: .analyticsHub,
            type: .campaignCreation,
            hasCampaigns: viewModel.googleCampaignsCard.campaignsData.isNotEmpty
        ))
    }
}

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    /// Environment safe areas
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    /// Set this closure with UIKit code to pop the view controller and display the provided notice.
    /// Needed because we need access to the UIHostingController `popViewController` method.
    ///
    var dismissWithNotice: ((Notice) -> Void) = { _ in }

    /// Set this closure with UIKit code to create a new Google Ads campaign.
    var onCreateNewGoogleAdsCampaign: (() -> Void)?

    @StateObject var viewModel: AnalyticsHubViewModel

    var body: some View {
        RefreshablePlainList(action: {
            viewModel.trackAnalyticsInteraction()
            await viewModel.updateData()
        }) {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                AnalyticsTimeRangeCard(viewModel: viewModel.timeRangeCard,
                                       selectionType: $viewModel.timeRangeSelectionType)
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(uiColor: .listForeground(modal: false)))
                .addingTopAndBottomDividers()

                ForEach(viewModel.enabledCards, id: \.self) { card in
                    analyticsCard(type: card)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground(modal: false)))
                        .addingTopAndBottomDividers()
                }

                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
        .edgesIgnoringSafeArea(.horizontal)
        .task {
            await viewModel.loadAnalyticsCardSettings()
            await viewModel.updateData()
        }
        .onReceive(viewModel.$dismissNotice) { notice in
            guard let notice else { return }
            dismissWithNotice(notice)
        }
        .gesture(
            // Detects when scrolling begins so it can be tracked.
            DragGesture().onChanged({ _ in
                viewModel.trackAnalyticsInteraction()
            })
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.customizeAnalytics()
                } label: {
                    Text(Localization.editButton)
                }
            }
        }
        .sheet(item: $viewModel.customizeAnalyticsViewModel) { customizeViewModel in
            NavigationView {
                AnalyticsHubCustomizeView(viewModel: customizeViewModel)
            }
        }
    }
}

private extension AnalyticsHubView {
    /// Creates an analytics card for the given type.
    /// - Parameter type: Type of analytics card, e.g. revenue or orders.
    @ViewBuilder
    func analyticsCard(type: AnalyticsCard.CardType) -> some View {
        switch type {
        case .revenue:
            AnalyticsReportCard(viewModel: viewModel.revenueCard)
        case .orders:
            AnalyticsReportCard(viewModel: viewModel.ordersCard)
        case .products:
            AnalyticsTopPerformersCard(statsViewModel: viewModel.productsStatsCard, itemsViewModel: viewModel.itemsSoldCard)
        case .sessions:
            AnalyticsSessionsReportCard(viewModel: viewModel.sessionsCard)
        case .bundles:
            AnalyticsTopPerformersCard(bundlesViewModel: viewModel.bundlesCard)
        case .giftCards:
            AnalyticsReportCard(viewModel: viewModel.giftCardsCard)
        case .googleCampaigns:
            GoogleAdsCampaignReportCard(viewModel: viewModel.googleCampaignsCard,
                                        onCreateNewCampaign: {
                onCreateNewGoogleAdsCampaign?()
            })
        }
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")
        static let editButton = NSLocalizedString("analyticsHub.editButton.label",
                                                  value: "Edit",
                                                  comment: "Label for button that opens a screen to customize the Analytics Hub")
    }

    struct Layout {
        static let verticalSpacing: CGFloat = 24.0
    }
}

// MARK: Preview

struct AnalyticsHubPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsHubView(viewModel: AnalyticsHubViewModel(siteID: 123,
                                                              timeZone: .current,
                                                              statsTimeRange: .thisYear,
                                                              usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()))
        }
    }
}
