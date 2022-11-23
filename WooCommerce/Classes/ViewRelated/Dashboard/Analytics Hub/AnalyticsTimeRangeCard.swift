import SwiftUI

struct AnalyticsTimeRangeCard: View {

    let timeRangeTitle: String
    let currentRangeDescription: String
    let previousRangeDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(Color(UIColor.systemGray6))
                        .frame(width: Layout.calendarCircleWidth)
                    Image(uiImage: .calendar)
                }
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

private extension AnalyticsTimeRangeCard {
    enum Layout {
        static let calendarCircleWidth: CGFloat = 48
        static let verticalSpacing: CGFloat = 16
    }

    enum Localization {
        static let previousRangeComparisonContent = NSLocalizedString(
            "Compared to **%1$@**",
            comment: "Subtitle describing the previous analytics period under comparison. E.g. Compared to Oct 1 - 22, 2022"
        )
    }
}

struct TimeRangeCard_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsTimeRangeCard(timeRangeTitle: "Month to Date",
                               currentRangeDescription: "Nov 1 - 23, 2022",
                               previousRangeDescription: "Oct 1 - 23, 2022")
    }
}
