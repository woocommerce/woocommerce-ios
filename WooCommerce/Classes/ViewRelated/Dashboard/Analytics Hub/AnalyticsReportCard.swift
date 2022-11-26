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

            HStack(alignment: .top) {

                /// Leading Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnSpacing) {

                    Text(leadingTitle)
                        .calloutStyle()

                    Text(leadingValue)
                        .titleStyle()

                    DeltaTag(value: leadingDelta, backgroundColor: leadingDeltaColor)

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                /// Trailing Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnSpacing) {
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

// MARK: Constants
private extension AnalyticsReportCard {
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let columnSpacing: CGFloat = 10
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
