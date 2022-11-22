import SwiftUI

struct TimeRangeCard: View {

    let timeRangeTitle: String
    let currentRangeDescription: String
    let previousRangeDescription: String

    var body: some View {
        VStack(alignment: .leading) {
            Divider()

            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(.gray)
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
            .frame(minHeight: Layout.selectedRangeMinHeight)

            Divider()

            BoldableTextView(String.localizedStringWithFormat(Localization.previousRangeComparisonContent, previousRangeDescription))
                .padding(.leading)
                .frame(maxWidth: .infinity, minHeight: Layout.previousRangeMinHeight, alignment: .leading)
                .font(.callout)
                .foregroundColor(Color(.textSubtle))

            Divider()
        }
        .background(Color(uiColor: .listForeground))
    }
}

private extension TimeRangeCard {
    enum Layout {
        static let calendarCircleWidth: CGFloat = 48
        static let selectedRangeMinHeight: CGFloat = 72
        static let previousRangeMinHeight: CGFloat = 32
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
        let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisMonth)
        TimeRangeCard(
            timeRangeTitle: timeRange.selectionType.rawValue,
            currentRangeDescription: timeRange.currentRangeDescription, previousRangeDescription: timeRange.previousRangeDescription)
    }
}
