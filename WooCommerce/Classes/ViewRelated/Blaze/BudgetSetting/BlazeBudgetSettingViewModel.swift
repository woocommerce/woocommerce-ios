import Foundation
import Yosemite

/// View model for `BlazeBudgetSettingView`
final class BlazeBudgetSettingViewModel: ObservableObject {
    @Published var dailyAmount: Double
    /// Using Double because Slider doesn't work with Int
    @Published var dayCount: Double
    @Published var startDate: Date

    @Published private(set) var forecastedImpressionState = ForecastedImpressionState.loading

    let dailyAmountSliderRange = Constants.minimumDailyAmount...Constants.maximumDailyAmount

    /// Using Double because Slider doesn't work with Int
    let dayCountSliderRange = Double(Constants.minimumDayCount)...Double(Constants.maximumDayCount)

    var dailyAmountText: String {
        let formattedAmount = String(format: "$%.0f", dailyAmount)
        return String.localizedStringWithFormat(Localization.dailyAmount, formattedAmount)
    }

    var totalAmountText: String {
        return String(format: "$%.0f USD", totalBudget)
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

    var formattedDateRange: String {
        // Use the configured formatter to generate the string.
        dateFormatter.string(from: startDate, to: endDate)
    }

    private let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var endDate: Date {
        Date(timeInterval: Constants.oneDayInSeconds * dayCount, since: startDate)
    }

    private var totalBudget: Double {
        dailyAmount * dayCount
    }

    private let siteID: Int64
    private let targetOptions: BlazeTargetOptions?
    private let stores: StoresManager

    typealias BlazeBudgetSettingCompletionHandler = (_ dailyBudget: Double, _ duration: Int, _ startDate: Date) -> Void
    private let completionHandler: BlazeBudgetSettingCompletionHandler

    init(siteID: Int64,
         dailyBudget: Double,
         duration: Int,
         startDate: Date,
         targetOptions: BlazeTargetOptions? = nil,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping BlazeBudgetSettingCompletionHandler) {
        self.siteID = siteID
        self.dailyAmount = dailyBudget
        self.dayCount = Double(duration)
        self.startDate = startDate
        self.targetOptions = targetOptions
        self.stores = stores
        self.completionHandler = onCompletion
    }

    func confirmSettings() {
        // TODO: track confirmation
        completionHandler(dailyAmount, Int(dayCount), startDate)
    }

    @MainActor
    func updateImpressions() async {
        forecastedImpressionState = .loading
        let input = BlazeForecastedImpressionsInput(startDate: startDate, endDate: endDate, totalBudget: totalBudget, targetings: targetOptions)
        do {
            let result = try await fetchForecastedImpressions(input: input)
            let formattedImpressions = String(format: "%d - %d", result.totalImpressionsMin, result.totalImpressionsMax)
            forecastedImpressionState = .result(formattedResult: formattedImpressions)
        } catch {
            DDLogError("⛔️ Error fetching forecasted impression: \(error)")
            forecastedImpressionState = .failure
        }
    }
}

// MARK: - Private helpers
private extension BlazeBudgetSettingViewModel {

    @MainActor
    func fetchForecastedImpressions(input: BlazeForecastedImpressionsInput) async throws -> BlazeImpressions {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(BlazeAction.fetchForecastedImpressions(siteID: siteID, input: input) { result in
                switch result {
                case .success(let impressions):
                    continuation.resume(returning: impressions)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}

// MARK: - subtypes
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

    enum ForecastedImpressionState {
        case loading
        case result(formattedResult: String)
        case failure
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
