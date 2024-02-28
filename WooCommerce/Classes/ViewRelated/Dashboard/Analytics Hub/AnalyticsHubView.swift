import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {

    /// Presents an error notice in the tab bar context after this `self` is dismissed.
    ///
    private let systemNoticePresenter: NoticePresenter

    /// Defines a notice that should be presented after `self` is dismissed.
    /// Defaults to `nil`.
    ///
    var notice: Notice?

    init(siteID: Int64,
         timeZone: TimeZone,
         timeRange: StatsTimeRangeV4,
         systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        let viewModel = AnalyticsHubViewModel(siteID: siteID, timeZone: timeZone, statsTimeRange: timeRange, usageTracksEventEmitter: usageTracksEventEmitter)
        self.systemNoticePresenter = systemNoticePresenter
        super.init(rootView: AnalyticsHubView(viewModel: viewModel))

        // Needed to pop the hosting controller from within the SwiftUI view
        rootView.dismissWithNotice = { [weak self] notice in
            self?.notice = notice
            self?.navigationController?.popViewController(animated: true)
        }
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

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    /// Environment safe areas
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    /// Set this closure with UIKit code to pop the view controller and display the provided notice.
    /// Needed because we need access to the UIHostingController `popViewController` method.
    ///
    var dismissWithNotice: ((Notice) -> Void) = { _ in }

    @StateObject var viewModel: AnalyticsHubViewModel

    @State private var isEnablingJetpackStats = false

    var body: some View {
        RefreshablePlainList(action: {
            viewModel.trackAnalyticsInteraction()
            await viewModel.updateData()
        }) {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsTimeRangeCard(viewModel: viewModel.timeRangeCard,
                                           selectionType: $viewModel.timeRangeSelectionType)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground(modal: false)))

                    Divider()
                }

                if viewModel.enabledCards.isEmpty {
                    EmptyState(title: Localization.emptyStateTitle, description: Localization.emptyStateDescription, image: .enableAnalyticsImage)
                } else {
                    ForEach(viewModel.enabledCards, id: \.self) { card in
                        analyticsCard(type: card)
                    }
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
                .renderedIf(viewModel.canCustomizeAnalytics)
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
            VStack(spacing: Layout.dividerSpacing) {
                Divider()

                AnalyticsReportCard(viewModel: viewModel.revenueCard)
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(uiColor: .listForeground(modal: false)))

                Divider()
            }
        case .orders:
            VStack(spacing: Layout.dividerSpacing) {
                Divider()

                AnalyticsReportCard(viewModel: viewModel.ordersCard)
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(uiColor: .listForeground(modal: false)))

                Divider()
            }
        case .products:
            VStack(spacing: Layout.dividerSpacing) {
                Divider()

                AnalyticsProductCard(statsViewModel: viewModel.productsStatsCard, itemsViewModel: viewModel.itemsSoldCard)
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(uiColor: .listForeground(modal: false)))

                Divider()
            }
        case .sessions:
            VStack(spacing: Layout.dividerSpacing) {
                Divider()

                Group {
                    if viewModel.showJetpackStatsCTA {
                        AnalyticsCTACard(title: Localization.sessionsCTATitle,
                                         message: Localization.sessionsCTAMessage,
                                         buttonLabel: Localization.sessionsCTAButton,
                                         isLoading: $isEnablingJetpackStats) {
                            isEnablingJetpackStats = true
                            await viewModel.enableJetpackStats()
                            isEnablingJetpackStats = false
                        }
                    } else {
                        AnalyticsReportCard(viewModel: viewModel.sessionsCard)
                    }
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(uiColor: .listForeground(modal: false)))

                Divider()
            }
        }
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")


        static let sessionsCTATitle = NSLocalizedString("analyticsHub.jetpackStatsCTA.title",
                                                        value: "SESSIONS",
                                                        comment: "Title for sessions section in the Analytics Hub")
        static let sessionsCTAMessage = NSLocalizedString("analyticsHub.jetpackStatsCTA.message",
                                                          value: "Enable Jetpack Stats to see your store's session analytics.",
                                                          comment: "Text displayed in the Analytics Hub when the Jetpack Stats module is disabled")
        static let sessionsCTAButton = NSLocalizedString("analyticsHub.jetpackStatsCTA.buttonLabel",
                                                         value: "Enable Jetpack Stats",
                                                         comment: "Label for button to enable Jetpack Stats")
        static let editButton = NSLocalizedString("analyticsHub.editButton.label",
                                                  value: "Edit",
                                                  comment: "Label for button that opens a screen to customize the Analytics Hub")

        static let emptyStateTitle = NSLocalizedString("analyticsHub.emptyState.title",
                                                       value: "No analytics available",
                                                       comment: "Title when there are no analytics to display in the Analytics Hub.")
        static let emptyStateDescription = NSLocalizedString("analyticsHub.emptyState.description",
                                                             value: "Please select another date range or tap Edit to enable more analytics.",
                                                             comment: "Description when there are no analytics to display in the Analytics Hub.")
    }

    struct Layout {
        static let verticalSpacing: CGFloat = 24.0
        static let dividerSpacing: CGFloat = .zero
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
