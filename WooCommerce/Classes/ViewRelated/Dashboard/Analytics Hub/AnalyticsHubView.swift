import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {

    /// Presents an error notice in the tab bar context after this `self` is dismissed.
    ///
    private let systemNoticePresenter: NoticePresenter

    init(siteID: Int64, timeRange: StatsTimeRangeV4, systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        let viewModel = AnalyticsHubViewModel(siteID: siteID, statsTimeRange: timeRange)
        self.systemNoticePresenter = systemNoticePresenter
        super.init(rootView: AnalyticsHubView(viewModel: viewModel))

        // Needed to pop the hosting controller from within the SwiftUI view
        rootView.dismiss = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Show any notice that should have been presented before the underlying disappears.
        enqueuePendingNotice(rootView.viewModel.notice, using: systemNoticePresenter)
    }
}

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    /// Environment safe areas
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    /// Set this closure with UIKit code to pop the view controller. Needed because we need access to the UIHostingController `popViewController` method.
    ///
    var dismiss: (() -> Void) = {}

    @StateObject var viewModel: AnalyticsHubViewModel

    var body: some View {
        RefreshablePlainList(action: {
            await viewModel.updateData()
        }) {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsTimeRangeCard(viewModel: viewModel.timeRangeCard,
                                           selectionType: $viewModel.timeRangeSelectionType)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.revenueCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.ordersCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsProductCard(viewModel: viewModel.productCard)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }

                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
        .edgesIgnoringSafeArea(.horizontal)
        .task {
            await viewModel.updateData()
            if viewModel.errorSelectingTimeRange {
                dismiss()
            }
        }
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
            AnalyticsHubView(viewModel: AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisYear))
        }
    }
}
