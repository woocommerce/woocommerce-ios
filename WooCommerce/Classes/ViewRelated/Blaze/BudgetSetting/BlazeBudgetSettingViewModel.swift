import Foundation

/// View model for `BlazeBudgetSettingView`
final class BlazeBudgetSettingViewModel: ObservableObject {
    @Published var dailyAmount: Double

    /// Using Double because Slider doesn't work with Int
    @Published var dayCount: Double

    @Published var startDate: Date

    typealias BlazeBudgetSettingCompletionHandler = (_ dailyBudget: Double, _ duration: Int, _ startDate: Date) -> Void
    private let completionHandler: BlazeBudgetSettingCompletionHandler

    let dailyAmountSliderRange = Constants.minimumDailyAmount...Constants.maximumDailyAmount

    /// Using Double because Slider doesn't work with Int
    let dayCountSliderRange = Double(Constants.minimumDayCount)...Double(Constants.maximumDayCount)

    var dailyAmountText: String {
        let formattedAmount = String(format: "$%.0f", dailyAmount)
        return String.localizedStringWithFormat(Localization.dailyAmount, formattedAmount)
    }

    var totalAmountText: String {
        let totalAmount = dailyAmount * dayCount
        return String(format: "$%.0f USD", totalAmount)
    }

    var formattedTotalDuration: String {
        String.pluralize(Int(dayCount),
                         singular: Localization.totalDurationSingleDay,
                         plural: Localization.totalDurationMultipleDays)
    }

    var formattedDayCount: String {
        String.pluralize(Int(dayCount),
                         singular: Localization.singleDay,
                         plural: Localization.multipleDays)
    }

    private let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var formattedDateRange: String {
        let endDate = Date(timeInterval: Constants.oneDayInSeconds * dayCount, since: startDate)

        // Use the configured formatter to generate the string.
        return dateFormatter.string(from: startDate, to: endDate)
    }

    init(dailyBudget: Double, duration: Int, startDate: Date, onCompletion: @escaping BlazeBudgetSettingCompletionHandler) {
        self.dailyAmount = dailyBudget
        self.dayCount = Double(duration)
        self.startDate = startDate
        self.completionHandler = onCompletion
    }

    func confirmSettings() {
        // TODO: track confirmation
        completionHandler(dailyAmount, Int(dayCount), startDate)
    }
}

extension BlazeBudgetSettingViewModel {
    enum Constants {
        static let oneDayInSeconds: Double = 86400
        static let minimumDailyAmount: Double = 5
        static let maximumDailyAmount: Double = 50
        static let dailyAmountSliderStep: Double = 1
        static let minimumDayCount = 1
        static let maximumDayCount = 28
        static let defaultDayCount = 7
        static let dayCountSliderStep = 1
    }

    private enum Localization {
        static let dailyAmount = NSLocalizedString(
            "blazeBudgetSettingViewModel.dailyAmount",
            value: "%1$@ daily",
            comment: "The formatted amount to be spent on a Blaze campaign daily. " +
            "Reads like: $15 daily"
        )
        static let singleDay = NSLocalizedString(
            "blazeBudgetSettingViewModel.singleDay",
            value: "%1$d day",
            comment: "The duration for a Blaze campaign in singular form."
        )
        static let multipleDays = NSLocalizedString(
            "blazeBudgetSettingViewModel.multipleDays",
            value: "%1$d days",
            comment: "The duration for a Blaze campaign in plural form. " +
            "Reads like: 10 days"
        )
        static let totalDurationSingleDay = NSLocalizedString(
            "blazeBudgetSettingViewModel.totalDurationSingleDay",
            value: "for %1$d day",
            comment: "The total duration for a Blaze campaign in singular form. " +
            "Reads like: for 1 day"
        )
        static let totalDurationMultipleDays = NSLocalizedString(
            "blazeBudgetSettingViewModel.totalDurationMultipleDays",
            value: "for %1$d days",
            comment: "The total duration for a Blaze campaign in plural form. " +
            "Reads like: for 10 days"
        )
    }
}
