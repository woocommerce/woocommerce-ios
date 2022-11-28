import SwiftUI

/// Reusable Time Range card made for the Analytics Hub.
///
struct AnalyticsTimeRangeCard: View {

    @StateObject var viewModel: AnalyticsHubViewModel

    @State private var showTimeRangeSelectionView: Bool = false

    var body: some View {
        createTimeRangeContent()
            .sheet(isPresented: $showTimeRangeSelectionView) {
                SelectionList(title: "Select something",
                              items: AnalyticsHubViewModel.SelectionType.allCases,
                              contentKeyPath: \.description,
                              selected: $viewModel.timeRangeSelectionType)
            }
    }

    private func createTimeRangeContent() -> some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack {
                Image(uiImage: .calendar)
                    .padding()
                    .background(Circle().foregroundColor(Color(.systemGray6)))
                VStack(alignment: .leading, spacing: .zero) {
                    Text(viewModel.timeRangeCard.selectedRangeTitle)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                    Text(viewModel.timeRangeCard.currentRangeSubtitle)
                        .bold()
                }
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading)

            Divider()

            BoldableTextView(Localization.comparisonHeaderTextWith(viewModel.timeRangeCard.previousRangeSubtitle))
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .calloutStyle()
        }
        .padding([.top, .bottom])
        .onTapGesture {
            showTimeRangeSelectionView.toggle()
        }
    }
}

struct TimeRangeSelectionView: View {
    var body: some View {
        Text("Time range Selection")
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

        static func comparisonHeaderTextWith(_ rangeDescription: String) -> String {
            return String.localizedStringWithFormat(Localization.previousRangeComparisonContent, rangeDescription)
        }
    }
}
//
//// MARK: Previews
//struct TimeRangeCard_Previews: PreviewProvider {
//    static var previews: some View {
//        AnalyticsTimeRangeCard(timeRangeTitle: "Month to Date",
//                               currentRangeDescription: "Nov 1 - 23, 2022",
//                               previousRangeDescription: "Oct 1 - 23, 2022")
//    }
//}
