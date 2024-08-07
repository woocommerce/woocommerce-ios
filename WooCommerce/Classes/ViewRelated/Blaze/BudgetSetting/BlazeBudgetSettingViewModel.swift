import Combine
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `BlazeBudgetSettingView`
final class BlazeBudgetSettingViewModel: ObservableObject {
    @Published var dailyAmount: Double
    /// Using Double because Slider doesn't work with Int
    /// This is readonly and will be updated through `didTapApplyDuration`.
    @Published private(set) var dayCount: Double

    /// This is readonly and will be updated through `didTapApplyDuration`.
    @Published private(set) var startDate: Date

    @Published private(set) var forecastedImpressionState = ForecastedImpressionState.loading

    // Whether the campaign should have no end date
    @Published var isEvergreen: Bool

    let dailyAmountSliderRange = Constants.minimumDailyAmount...Constants.maximumDailyAmount

    /// Using Double because Slider doesn't work with Int
    let dayCountSliderRange = Double(Constants.minimumDayCount)...Double(Constants.maximumDayCount)

    let minDayAllowedInPickerSelection = Date.now + 60 * 60 * 24 // Current date + 1 day

    // Start date needs to be inside the accepted range that is max 60 days from today
    // (internally, we validate 61 to simplify the logic related to timezones).
    let maxDayAllowedInPickerSelection = Calendar.current.date(byAdding: .day, value: 61, to: Date())!

    var dailyAmountText: String {
        let formattedAmount = String(format: "$%.0f", dailyAmount)
        return String.localizedStringWithFormat(Localization.dailyAmount, formattedAmount)
    }

    var weeklyAmountText: String {
        let totalBudget = calculateTotalBudget(dailyBudget: dailyAmount, dayCount: 7)
        return String.localizedStringWithFormat(Localization.totalBudget, totalBudget)
    }

    var totalAmountText: String {
        let totalBudget = calculateTotalBudget(dailyBudget: dailyAmount, dayCount: dayCount)
        return String.localizedStringWithFormat(Localization.totalBudget, totalBudget)
    }

    var formattedTotalDuration: String {
        String.pluralize(Int(dayCount),
                         singular: Localization.totalDurationSingleDay,
                         plural: Localization.totalDurationMultipleDays)
    }

    var formattedDateRange: String {
        if isEvergreen {
            let formattedStartDate = startDate.toString(dateStyle: .medium, timeStyle: .none)
            return String(format: Localization.evergreenCampaignDate, formattedStartDate)
        } else {
            let endDate = calculateEndDate(from: startDate, dayCount: dayCount)
            return dateFormatter.string(from: startDate, to: endDate)
        }
    }

    private let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private let siteID: Int64
    private let locale: Locale
    private let timeZone: TimeZone
    private let targetOptions: BlazeTargetOptions?
    private let stores: StoresManager
    private let analytics: Analytics

    typealias BlazeBudgetSettingCompletionHandler = (_ dailyBudget: Double, _ isEvergreen: Bool, _ duration: Int, _ startDate: Date) -> Void
    private let completionHandler: BlazeBudgetSettingCompletionHandler

    private var settingSubscription: AnyCancellable?

    init(siteID: Int64,
         dailyBudget: Double,
         isEvergreen: Bool,
         duration: Int,
         startDate: Date,
         locale: Locale = .current,
         timeZone: TimeZone = .current,
         targetOptions: BlazeTargetOptions? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping BlazeBudgetSettingCompletionHandler) {
        self.siteID = siteID
        self.dailyAmount = dailyBudget
        self.isEvergreen = isEvergreen
        self.dayCount = Double(duration)
        self.startDate = startDate
        self.locale = locale
        self.timeZone = timeZone
        self.targetOptions = targetOptions
        self.stores = stores
        self.analytics = analytics
        self.completionHandler = onCompletion

        observeSettings()
    }

    func didTapApplyDuration(dayCount: Double, since startDate: Date) {
        analytics.track(event: .Blaze.Budget.changedDuration(Int(dayCount)))
        self.dayCount = dayCount
        self.startDate = startDate
    }

    func formatDayCount(_ count: Double) -> String {
        String.pluralize(Int(count),
                         singular: Localization.singleDay,
                         plural: Localization.multipleDays)
    }

    func confirmSettings() {
        let days = Int(dayCount)
        let totalBudget = calculateTotalBudget(dailyBudget: dailyAmount, dayCount: dayCount)
        analytics.track(event: .Blaze.Budget.updateTapped(duration: days,
                                                          totalBudget: totalBudget))
        completionHandler(dailyAmount, isEvergreen, days, startDate)
    }

    @MainActor
    func retryFetchingImpressions() async {
        await updateImpressions(startDate: startDate, dayCount: dayCount, dailyBudget: dailyAmount)
    }

    @MainActor
    func updateImpressions(startDate: Date, dayCount: Double, dailyBudget: Double) async {
        forecastedImpressionState = .loading
        let endDate = calculateEndDate(from: startDate, dayCount: dayCount)
        let totalBudget = calculateTotalBudget(dailyBudget: dailyBudget, dayCount: dayCount)
        let input = BlazeForecastedImpressionsInput(startDate: startDate,
                                                    endDate: endDate,
                                                    timeZone: timeZone.identifier,
                                                    totalBudget: totalBudget,
                                                    targeting: targetOptions)
        do {
            let result = try await fetchForecastedImpressions(input: input)
            let formattedImpressions = String(format: "%d - %d",
                                              locale: locale,
                                              result.totalImpressionsMin,
                                              result.totalImpressionsMax)
            forecastedImpressionState = .result(formattedResult: formattedImpressions)
        } catch {
            DDLogError("⛔️ Error fetching forecasted impression: \(error)")
            forecastedImpressionState = .failure
        }
    }
}

// MARK: - Private helpers
private extension BlazeBudgetSettingViewModel {

    func observeSettings() {
        settingSubscription = $dayCount.combineLatest($dailyAmount, $startDate)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] dayCount, dailyBudget, startDate in
                guard let self else { return }
                Task {
                    await self.updateImpressions(startDate: startDate, dayCount: dayCount, dailyBudget: dailyBudget)
                }
            }
    }

    func calculateEndDate(from startDate: Date, dayCount: Double) -> Date {
        Date(timeInterval: Constants.oneDayInSeconds * dayCount, since: startDate)
    }

    func calculateTotalBudget(dailyBudget: Double, dayCount: Double) -> Double {
        dailyBudget * dayCount
    }

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

    enum ForecastedImpressionState: Equatable {
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
        static let totalBudget = NSLocalizedString(
            "blazeBudgetSettingViewModel.totalBudget",
            value: "$%.0f USD",
            comment: "The formatted total budget for a Blaze campaign, fixed in USD. " +
            "Reads as $11 USD. Keep %.0f as is."
        )
        static let evergreenCampaignDate = NSLocalizedString(
            "blazeBudgetSettingViewModel.evergreenCampaignDate",
            value: "Starting from %1$@",
            comment: "The formatted date for an evergreen Blaze campaign, with the starting date in the placeholder. " +
            "Read as Starting from May 11."
        )
    }
}
