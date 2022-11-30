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

                    if let viewModel = viewModel.revenueCard {
                        AnalyticsReportCard(viewModel: viewModel)
                            .padding(.horizontal, insets: safeAreaInsets)
                            .background(Color(uiColor: .listForeground))
                    } else {
                        emptyCard(message: Localization.noRevenue)
                    }

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    if let viewModel = viewModel.ordersCard {
                        AnalyticsReportCard(viewModel: viewModel)
                            .padding(.horizontal, insets: safeAreaInsets)
                            .background(Color(uiColor: .listForeground))
                    } else {
                        emptyCard(message: Localization.noOrders)
                    }

                    Divider()
                }

                VStack(spacing: Layout.dividerSpacing) {
                    Divider()

                    if let viewModel = viewModel.productCard {
                        AnalyticsProductCard(viewModel: viewModel)
                            .padding(.horizontal, insets: safeAreaInsets)
                            .background(Color(uiColor: .listForeground))
                    } else {
                        emptyCard(message: Localization.noProducts)
                    }

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
        }
    }

    @ViewBuilder
    private func emptyCard(message: String) -> some View {
        Text(message)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color(.text))
            .subheadlineStyle()
            .padding()
            .background(Color(uiColor: .listForeground))
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")
        static let noRevenue = NSLocalizedString("Unable to load revenue analytics",
                                                 comment: "Text displayed when there is an error loading revenue stats data.")
        static let noOrders = NSLocalizedString("Unable to load order analytics",
                                                comment: "Text displayed when there is an error loading order stats data.")
        static let noProducts = NSLocalizedString("Unable to load product analytics",
                                                  comment: "Text displayed when there is an error loading product stats data.")
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
