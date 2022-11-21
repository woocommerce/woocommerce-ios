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
                VStack(alignment: .leading) {

                    Text("Left Subtitle")
                        .calloutStyle()

                    Text(totalSales)
                        .titleStyle()

                    Text(totalGrowth)
                        .foregroundColor(Color(.textInverted))
                        .captionStyle()
                        .padding(8)
                        .background(Color(totalGrowthColor))

                }

                VStack(alignment: .leading) {

                    Text("Right Subtitle")
                        .calloutStyle()

                    Text(netSales)
                        .titleStyle()

                    Text(netGrowth)
                        .foregroundColor(Color(.textInverted))
                        .captionStyle()
                        .padding(8)
                        .background(Color(netGrowth))
                }
            }
        }
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
