import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {
    init(timeRange: StatsTimeRangeV4) {
        super.init(rootView: AnalyticsHubView())
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.vertialSpacing) {
                VStack(spacing: 0) {
                    Divider()
                    Text("Placeholder for Time Range Selection")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }


                VStack(spacing: 0) {
                    Divider()

                    AnalyticsReportCard(title: Localization.revenue,
                                        totalSales: "$3.234",
                                        totalGrowth: "+23%",
                                        totalGrowthColor: .withColorStudio(.green, shade: .shade50),
                                        netSales: "$2.324",
                                        netGrowth: "-4%",
                                        netGrowthColor: .withColorStudio(.red, shade: .shade40))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: 0) {
                    Divider()

                    AnalyticsReportCard(title: Localization.orders,
                                        totalSales: "$2.934",
                                        totalGrowth: "+15%",
                                        totalGrowthColor: .withColorStudio(.green, shade: .shade50),
                                        netSales: "$1.624",
                                        netGrowth: "-9%",
                                        netGrowthColor: .withColorStudio(.red, shade: .shade40))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        static let revenue = NSLocalizedString("REVENUE", comment: "Title for the revenue report card on the analytics hub screen. Capitalized")
        static let orders = NSLocalizedString("ORDERS", comment: "Title for the orders report card on the analytics hub screen. Capitalized")
    }

    struct Layout {
        static let vertialSpacing: CGFloat = 24.0
    }
}

// MARK: Preview

struct AnalyticsHubPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsHubView()
        }
    }
}
