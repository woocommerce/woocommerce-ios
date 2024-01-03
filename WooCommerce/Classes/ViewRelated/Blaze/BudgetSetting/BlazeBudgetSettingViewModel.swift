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
}

extension BlazeBudgetSettingViewModel {
    enum Constants {
        static let minimumDailyAmount: Double = 5
        static let maximumDailyAmount: Double = 50
        static let minimumDayCount: Int = 1
        static let maximumDayCount: Int = 28
        static let dailyAmountSliderStep: Double = 1
    }

    private enum Localization {
        static let dailyAmount = NSLocalizedString(
            "blazeBudgetSettingViewModel.dailyAmount",
            value: "%1$@ daily",
            comment: "The formatted amount to be spent on a Blaze campaign daily. " +
            "Reads like: $15 daily"
        )
    }
}
