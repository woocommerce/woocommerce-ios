import SwiftUI

/// Resuable report card made for the Analytics Hub.
///
struct AnalyticsReportCard: View {

    let title: String
    let totalSales: String
    let totalGrowth: String
    let totalGrowthColor: UIColor
    let netSales: String
    let netGrowth: String
    let netGrowthColor: UIColor

    var body: some View {
        VStack(alignment: .leading) {

            Text(title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            HStack {

                /// Total Sales
                ///
                VStack(alignment: .leading) {

                    Text(Localization.totalSales)
                        .calloutStyle()

                    Text(totalSales)
                        .titleStyle()

                    Text(totalGrowth)
                        .foregroundColor(Color(.textInverted))
                        .captionStyle()
                        .padding(Layout.growthBackgroundPadding)
                        .background(Color(totalGrowthColor))

                }

                /// Net Sales
                ///
                VStack(alignment: .leading) {
                    Text(Localization.netSales)
                        .calloutStyle()

                    Text(netSales)
                        .titleStyle()

                    Text(netGrowth)
                        .foregroundColor(Color(.textInverted))
                        .captionStyle()
                        .padding(Layout.growthBackgroundPadding)
                        .background(Color(netGrowthColor))
                }
            }
        }
    }
}

// MARK: Constants
private extension AnalyticsReportCard {
    enum Localization {
        static let totalSales = NSLocalizedString("Total Sales", comment: "Total Sales subtitle on the analytics hub report card.")
        static let netSales = NSLocalizedString("Net Sales", comment: "Net Sales subtitle on the analytics hub report card.")
    }

    enum Layout {
        static let growthBackgroundPadding = EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
    }
}

// MARK: Previews
struct Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsReportCard(title: "REVENUE",
                            totalSales: "$3.678",
                            totalGrowth: "+23%",
                            totalGrowthColor: .systemGreen,
                            netSales: "$3.232",
                            netGrowth: "-3%",
                            netGrowthColor: .systemRed)
            .previewLayout(.sizeThatFits)
    }
}
