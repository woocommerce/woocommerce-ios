import UIKit
import Yosemite

private extension StatsTimeRangeV4 {
    func timeRangeText(startDate: Date, endDate: Date, timezone: TimeZone) -> String {
        let dateFormatter = timeRangeDateFormatter(timezone: timezone)
        switch self {
        case .today, .thisMonth, .thisYear:
            return dateFormatter.string(from: startDate)
        case .thisWeek:
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            return String.localizedStringWithFormat(NSLocalizedString("%1$@-%2$@", comment: "Displays a date range for a stats interval"), startDateString, endDateString)
        }
    }

    func timeRangeDateFormatter(timezone: TimeZone) -> DateFormatter {
        let dateFormatter: DateFormatter
        switch intervalGranularity {
        case .hourly:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .daily:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .weekly:
            dateFormatter = DateFormatter.Charts.chartAxisMonthFormatter
        case .monthly:
            dateFormatter = DateFormatter.Charts.chartAxisYearFormatter
        default:
            fatalError("This case is not supported: \(intervalGranularity.rawValue)")
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }
}

/// Contains a label that displays the time range - a date, date range for a week, month, or year.
class StatsTimeRangeBarView: UIView {
    // MARK: Subviews
    private let label = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureLabel()
    }

    /// Updates the label with start/end dates, time range type, and site time zone.
    func updateDates(startDate: Date,
                     endDate: Date,
                     timeRange: StatsTimeRangeV4,
                     timezone: TimeZone) {
        label.text = timeRange.timeRangeText(startDate: startDate,
                                             endDate: endDate,
                                             timezone: timezone)
    }
}

private extension StatsTimeRangeBarView {
    func configureLabel() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        pinSubviewToAllEdges(label, insets: Constants.labelInsets)

        label.font = StyleManager.subheadlineBoldFont
        label.textColor = StyleManager.defaultTextColor
    }
}

private extension StatsTimeRangeBarView {
    enum Constants {
        static let labelInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
}
