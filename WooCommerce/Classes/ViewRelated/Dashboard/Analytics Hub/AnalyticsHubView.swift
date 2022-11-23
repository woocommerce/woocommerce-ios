import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {
    init(timeRange: StatsTimeRangeV4) {
        let viewModel = AnalyticsHubViewModel(statsTimeRange: timeRange)
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
    @StateObject var viewModel: AnalyticsHubViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.vertialSpacing) {
                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsTimeRangeCard(viewModel: viewModel.timeRangeCard)
                    .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.revenueCard)
                    .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    AnalyticsReportCard(viewModel: viewModel.ordersCard)
                    .background(Color(uiColor: .listForeground))

                    Divider()
                }

                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")
    }

    struct Layout {
        static let vertialSpacing: CGFloat = 24.0
        static let dividerSpacing: CGFloat = .zero
    }
}

// MARK: Preview

struct AnalyticsHubPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsHubView(viewModel: AnalyticsHubViewModel(statsTimeRange: .thisYear))
        }
    }
}
