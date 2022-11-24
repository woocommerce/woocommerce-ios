import SwiftUI

/// Resuable Time Range card made for the Analytics Hub.
///
struct AnalyticsTimeRangeCard: View {

    let timeRangeTitle: String
    let currentRangeDescription: String
    let previousRangeDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack {
                Image(uiImage: .calendar)
                    .padding()
                    .background(Circle().foregroundColor(Color(.systemGray6)))
                VStack(alignment: .leading, spacing: .zero) {
                    Text(timeRangeTitle)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                    Text(currentRangeDescription)
                        .bold()
                }
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading)

            Divider()

            BoldableTextView(String.localizedStringWithFormat(Localization.previousRangeComparisonContent, previousRangeDescription))
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .calloutStyle()
        }
        .padding([.top, .bottom])
    }
}

// MARK: Constants
private extension AnalyticsTimeRangeCard {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
    }

    enum Localization {
        static let previousRangeComparisonContent = NSLocalizedString(
            "Compared to **%1$@**",
            comment: "Subtitle describing the previous analytics period under comparison. E.g. Compared to Oct 1 - 22, 2022"
        )
    }
}

// MARK: Previews
struct TimeRangeCard_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsTimeRangeCard(timeRangeTitle: "Month to Date",
                               currentRangeDescription: "Nov 1 - 23, 2022",
                               previousRangeDescription: "Oct 1 - 23, 2022")
    }
}
