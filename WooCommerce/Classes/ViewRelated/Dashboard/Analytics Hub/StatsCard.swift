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

                    GrowthTag(value: totalGrowth, backgroundColor: totalGrowthColor)

                }

                /// Net Sales
                ///
                VStack(alignment: .leading) {
                    Text(Localization.netSales)
                        .calloutStyle()

                    Text(netSales)
                        .titleStyle()

                    GrowthTag(value: netGrowth, backgroundColor: netGrowthColor)
                }
            }
        }
    }
}

private struct GrowthTag: View {

    let value: String
    let backgroundColor: UIColor

    var body: some View {
        Text(value)
            .padding(AnalyticsReportCard.Layout.growthBackgroundPadding)
            .foregroundColor(Color(.textInverted))
            .captionStyle()
            .background(Color(backgroundColor))
            .cornerRadius(AnalyticsReportCard.Layout.growthCornerRadius)
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
        static let growthCornerRadius: CGFloat = 4.0
    }
}

// MARK: Previews
struct Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsReportCard(title: "REVENUE",
                            totalSales: "$3.678",
                            totalGrowth: "+23%",
                            totalGrowthColor: .withColorStudio(.green, shade: .shade40),
                            netSales: "$3.232",
                            netGrowth: "-3%",
                            netGrowthColor: .withColorStudio(.red, shade: .shade40))
            .previewLayout(.sizeThatFits)
    }
}
