import SwiftUI

/// Resuable report card made for the Analytics Hub.
///
struct AnalyticsReportCard: View {

    let title: String
    let leadingTitle: String
    let leadingValue: String
    let leadingDelta: String
    let leadingDeltaColor: UIColor
    let trailingTitle: String
    let trailingValue: String
    let trailingDelta: String
    let trailingDeltaColor: UIColor

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {

            Text(title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            HStack {

                /// Leading Column
                ///
                VStack(alignment: .leading, spacing: Layout.salesColumnSpacing) {

                    Text(leadingTitle)
                        .calloutStyle()

                    Text(leadingValue)
                        .titleStyle()

                    DeltaTag(value: leadingDelta, backgroundColor: leadingDeltaColor)

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                /// Net Sales
                ///
                VStack(alignment: .leading, spacing: Layout.salesColumnSpacing) {
                    Text(trailingTitle)
                        .calloutStyle()

                    Text(trailingValue)
                        .titleStyle()

                    DeltaTag(value: trailingDelta, backgroundColor: trailingDeltaColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Layout.cardPadding)
    }
}

private struct DeltaTag: View {

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
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let salesColumnSpacing: CGFloat = 10
        static let growthBackgroundPadding = EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
        static let growthCornerRadius: CGFloat = 4.0
    }
}

// MARK: Previews
struct Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsReportCard(title: "REVENUE",
                            leadingTitle: "Total Sales",
                            leadingValue: "$3.678",
                            leadingDelta: "+23%",
                            leadingDeltaColor: .withColorStudio(.green, shade: .shade40),
                            trailingTitle: "Net Sales",
                            trailingValue: "$3.232",
                            trailingDelta: "-3%",
                            trailingDeltaColor: .withColorStudio(.red, shade: .shade40))
            .previewLayout(.sizeThatFits)
    }
}
