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
         timeRange: StatsTimeRangeV4,
         systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        let viewModel = AnalyticsHubViewModel(siteID: siteID, statsTimeRange: timeRange, usageTracksEventEmitter: usageTracksEventEmitter)
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

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.revenueCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground(modal: false)))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.ordersCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground(modal: false)))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsProductCard(statsViewModel: viewModel.productsStatsCard, itemsViewModel: viewModel.itemsSoldCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground(modal: false)))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.sessionsCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground(modal: false)))

                    Divider()
                }
                .renderedIf(viewModel.showSessionsCard)

                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
        .edgesIgnoringSafeArea(.horizontal)
        .task {
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
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")
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
                                                              statsTimeRange: .thisYear,
                                                              usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()))
        }
    }
}
