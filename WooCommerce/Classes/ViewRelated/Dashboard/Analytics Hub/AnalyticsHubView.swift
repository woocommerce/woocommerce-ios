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

                    AnalyticsReportCard(title: "REVENUE",
                                        leadingTitle: "Total Sales",
                                        leadingValue: "$3.234",
                                        leadingGrowth: "+23%",
                                        leadingGrowthColor: .withColorStudio(.green, shade: .shade50),
                                        trailingTitle: "Net Sales",
                                        trailingValue: "$2.324",
                                        trailingGrowth: "-4%",
                                        trailingGrowthColor: .withColorStudio(.red, shade: .shade40))
                    .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: 0) {
                    Divider()

                    AnalyticsReportCard(title: "ORDERS",
                                        leadingTitle: "Total Orders",
                                        leadingValue: "145",
                                        leadingGrowth: "+36%",
                                        leadingGrowthColor: .withColorStudio(.green, shade: .shade50),
                                        trailingTitle: "Average Order Value",
                                        trailingValue: "$57,99",
                                        trailingGrowth: "-16%",
                                        trailingGrowthColor: .withColorStudio(.red, shade: .shade40))
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
