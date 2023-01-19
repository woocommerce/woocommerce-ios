import SwiftUI

/// Reusable Time Range card made for the Analytics Hub.
///
struct AnalyticsTimeRangeCard: View {

    let timeRangeTitle: String
    let currentRangeDescription: String
    let previousRangeDescription: String
    @Binding var selectionType: AnalyticsHubTimeRangeSelection.SelectionType

    /// Determines if the time range selection should be shown.
    ///
    @State private var showTimeRangeSelectionView: Bool = false

    /// Determines if the custom range selection should be shown.
    ///
    @State private var showCustomRangeSelectionView: Bool = false

    /// Closure invoked when the time range card is tapped.
    ///
    private var onTapped: () -> Void

    /// Closure invoked when a time range is selected.
    ///
    private var onSelected: (Range) -> Void

    init(viewModel: AnalyticsTimeRangeCardViewModel, selectionType: Binding<AnalyticsHubTimeRangeSelection.SelectionType>) {
        self.timeRangeTitle = viewModel.selectedRangeTitle
        self.currentRangeDescription = viewModel.currentRangeSubtitle
        self.previousRangeDescription = viewModel.previousRangeSubtitle
        self.onSelected = viewModel.onSelected
        self.onTapped = viewModel.onTapped
        self._selectionType = selectionType
    }

    var body: some View {
        createTimeRangeContent()
            .sheet(isPresented: $showTimeRangeSelectionView) {
                SelectionList(title: Localization.timeRangeSelectionTitle,
                              items: Range.allCases,
                              contentKeyPath: \.description,
                              selected: internalSelectionBinding()) { selection in
                    onSelected(selection)
                }
                .sheet(isPresented: $showCustomRangeSelectionView) {
                    RangedDatePicker(startDate: selectionType.startDate, endDate: selectionType.endDate, datesFormatter: DatesFormatter()) { start, end in
                        showTimeRangeSelectionView = false // Dismiss the initial sheet for a smooth transition
                        self.selectionType = .custom(start: start, end: end)
                    }
                }
            }
    }

    private func createTimeRangeContent() -> some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Button(action: {
                showTimeRangeSelectionView.toggle()
                onTapped()
            }, label: {
                HStack {
                    Image(uiImage: .calendar)
                        .padding()
                        .foregroundColor(Color(.text))
                        .background(Circle().foregroundColor(Color(.systemGray6)))

                    VStack(alignment: .leading, spacing: .zero) {
                        Text(timeRangeTitle)
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()

                        Text(currentRangeDescription)
                            .foregroundColor(Color(.text))
                            .bold()
                    }
                    .padding(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(uiImage: .chevronDownImage)
                        .padding()
                        .foregroundColor(Color(.text))
                        .frame(alignment: .trailing)
                }
            })
            .buttonStyle(.borderless)
            .padding(.leading)
            .contentShape(Rectangle())

            Divider()

            BoldableTextView(Localization.comparisonHeaderTextWith(previousRangeDescription))
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .calloutStyle()
        }
        .padding([.top, .bottom])
        .frame(maxWidth: .infinity)
    }

    /// Tracks the range selection internally to determine if the custom range selection should be presented or not.
    /// If custom range selection is not needed, the internal selection is forwarded to `selectionType`.
    ///
    private func internalSelectionBinding() -> Binding<Range> {
        .init(
            get: {
                return selectionType.asTimeCardRange
            },
            set: { newValue in
                switch newValue {
                    // If we get a `custom` case it is because we need to present the custom range selection
                case .custom:
                    showCustomRangeSelectionView = true
                default:
                    // Any other selection should be forwarded to our parent binding.
                    selectionType = newValue.asAnalyticsHubRange
                }
            }
        )
    }
}

private extension AnalyticsTimeRangeCard {
    /// Specific `DatesFormatter` for the `RangedDatePicker` when presented in the analytics hub module.
    ///
    struct DatesFormatter: RangedDateTextFormatter {
        func format(start: Date, end: Date) -> String {
            start.formatAsRange(with: end, timezone: .current, calendar: Locale.current.calendar)
        }
    }
}

// MARK: Constants
private extension AnalyticsTimeRangeCard {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
    }

    enum Localization {
        static let timeRangeSelectionTitle = NSLocalizedString(
            "Date Range",
            comment: "Title describing the possible date range selections of the Analytics Hub"
        )
        static let previousRangeComparisonContent = NSLocalizedString(
            "Compared to **%1$@**",
            comment: "Subtitle describing the previous analytics period under comparison. E.g. Compared to Oct 1 - 22, 2022"
        )

        static func comparisonHeaderTextWith(_ rangeDescription: String) -> String {
            return String.localizedStringWithFormat(Localization.previousRangeComparisonContent, rangeDescription)
        }
    }
}

// MARK: Previews
struct TimeRangeCard_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AnalyticsTimeRangeCardViewModel(selectedRangeTitle: "Month to Date",
                                                        currentRangeSubtitle: "Nov 1 - 23, 2022",
                                                        previousRangeSubtitle: "Oct 1 - 23, 2022")
        AnalyticsTimeRangeCard(viewModel: viewModel, selectionType: .constant(.monthToDate))
    }
}


extension AnalyticsTimeRangeCard {
    enum Range: CaseIterable {
        case custom
        case today
        case yesterday
        case lastWeek
        case lastMonth
        case lastQuarter
        case lastYear
        case weekToDate
        case monthToDate
        case quarterToDate
        case yearToDate
    }
}
