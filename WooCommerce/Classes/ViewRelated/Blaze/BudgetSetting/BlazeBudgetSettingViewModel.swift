import Foundation

/// View model for `BlazeBudgetSettingView`
final class BlazeBudgetSettingViewModel: ObservableObject {
    @Published var dailyAmount = Constants.minimumDailyAmount

    /// Using Double because Slider doesn't work with Int
    @Published var dayCount = Double(Constants.maximumDayCount)

    @Published var startDate = Date.now

    let dailyAmountSliderRange = Constants.minimumDailyAmount...Constants.maximumDailyAmount

    var dailyAmountText: String {
        let formattedAmount = String(format: "$%.0f", dailyAmount)
        return String.localizedStringWithFormat(Localization.dailyAmount, formattedAmount)
    }

    var totalAmountText: String {
        let totalAmount = dailyAmount * dayCount
        return String(format: "$%.0f", totalAmount)
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
}

extension BlazeBudgetSettingViewModel {
    enum Constants {
        static let minimumDailyAmount: Double = 5
        static let maximumDailyAmount: Double = 50
        static let dailyAmountSliderStep: Double = 1
        static let minimumDayCount = 1
        static let maximumDayCount = 28
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
