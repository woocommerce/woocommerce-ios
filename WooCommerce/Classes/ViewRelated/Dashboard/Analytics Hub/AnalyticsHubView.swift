import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {
    init(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let viewModel = AnalyticsHubViewModel(siteID: siteID, statsTimeRange: timeRange)
        super.init(rootView: AnalyticsHubView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    /// Environment safe areas
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @StateObject var viewModel: AnalyticsHubViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsTimeRangeCard(viewModel: viewModel.timeRangeCard)
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

                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
        .edgesIgnoringSafeArea(.horizontal)
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
