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

    @Published var hasEndDate = false

    let dailyAmountSliderRange = Constants.minimumDailyAmount...Constants.maximumDailyAmount

    /// Using Double because Slider doesn't work with Int
    let dayCountSliderRange = Double(Constants.minimumDayCount)...Double(Constants.maximumDayCount)

    let minDayAllowedInPickerSelection = Date.now + 60 * 60 * 24 // Current date + 1 day

    // Start date needs to be inside the accepted range that is max 60 days from today
    // (internally, we validate 61 to simplify the logic related to timezones).
    let maxDayAllowedInPickerSelection = Calendar.current.date(byAdding: .day, value: 61, to: Date())!

    private var totalAmountText: String {
        let duration = hasEndDate ? dayCount : Double(Constants.dayCountInWeek)
        let totalBudget = calculateTotalBudget(dailyBudget: dailyAmount, dayCount: duration)
        return String.localizedStringWithFormat(Localization.totalBudget, totalBudget)
    }

    var formattedAmountAndDuration: NSAttributedString {
        let amount = totalAmountText
        let content: String = {
            guard hasEndDate else {
                return String.localizedStringWithFormat(Localization.weeklySpendAmount, amount)
            }
            if dayCount == 1 {
                return String.localizedStringWithFormat(Localization.totalAmountSingleDay, amount, Int(dayCount))
            } else {
                return String.localizedStringWithFormat(Localization.totalAmountMultipleDays, amount, Int(dayCount))
            }
        }()
        return createAttributedString(content: content,
                                      highlightedContent: amount,
                                      font: .headline)
    }

    var formattedDateRange: String {
        if hasEndDate {
            let endDate = calculateEndDate(from: startDate, dayCount: dayCount)
            return dateFormatter.string(from: startDate, to: endDate)
        } else {
            let formattedStartDate = startDate.toString(dateStyle: .medium, timeStyle: .none)
            return String(format: Localization.evergreenCampaignDate, formattedStartDate)
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
        self.hasEndDate = !isEvergreen
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
        analytics.track(event: .Blaze.Budget.changedSchedule(duration: Int(dayCount),
                                                             hasEndDate: hasEndDate))
        self.dayCount = dayCount
        self.startDate = startDate
    }

    func formatDayCount(_ count: Double) -> NSAttributedString {
        let dayCount = String.pluralize(Int(count),
                                        singular: Localization.singleDay,
                                        plural: Localization.multipleDays)
        let endDate = calculateEndDate(from: startDate, dayCount: count)
        let formattedEndDate = endDate.toString(dateStyle: .medium, timeStyle: .none)
        let content = String.localizedStringWithFormat(Localization.dayCountToEndDate, dayCount, formattedEndDate)
        return createAttributedString(content: content,
                                      highlightedContent: dayCount,
                                      font: .body,
                                      alignment: .right)
    }

    func confirmSettings() {
        let days = Int(dayCount)
        let totalBudget = calculateTotalBudget(dailyBudget: dailyAmount, dayCount: dayCount)
        analytics.track(event: .Blaze.Budget.updateTapped(duration: days,
                                                          totalBudget: totalBudget,
                                                          hasEndDate: hasEndDate))
        completionHandler(dailyAmount, !hasEndDate, days, startDate)
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
                                                    targeting: targetOptions,
                                                    isEvergreen: !hasEndDate)
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

    func createAttributedString(content: String,
                                highlightedContent: String,
                                font: UIFont,
                                alignment: NSTextAlignment = .center) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment

        let highlightedText = NSAttributedString(string: highlightedContent,
                                                 attributes: [.foregroundColor: UIColor.text.cgColor,
                                                              .font: font.bold,
                                                              .paragraphStyle: paragraph])
        let message = NSMutableAttributedString(string: content,
                                                attributes: [.font: font,
                                                             .paragraphStyle: paragraph,
                                                             .foregroundColor: UIColor.secondaryLabel.cgColor])
        message.replaceFirstOccurrence(of: highlightedContent, with: highlightedText)

        return message
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
        static let dayCountInWeek = 7
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
        static let dayCountToEndDate = NSLocalizedString(
            "blazeBudgetSettingViewModel.dayCountToEndDate",
            value: "%1$@ to %2$@",
            comment: "The duration for a Blaze campaign with an end date. " +
            "Placeholders are day count and formatted end date." +
            "Reads like: 10 days to Dec 19, 2024"
        )
        static let totalAmountSingleDay = NSLocalizedString(
            "blazeBudgetSettingViewModel.totalAmountSingleDay",
            value: "%1$@ for %2$d day",
            comment: "The total amount with duration for a Blaze campaign in singular form. " +
            "Reads like: $35 USD for 1 day"
        )
        static let totalAmountMultipleDays = NSLocalizedString(
            "blazeBudgetSettingViewModel.totalAmountMultipleDays",
            value: "%1$@ for %2$d days",
            comment: "The total amount with duration for a Blaze campaign in plural form. " +
            "Reads like: $35 USD for 7 days"
        )
        static let totalBudget = NSLocalizedString(
            "blazeBudgetSettingViewModel.totalBudget",
            value: "$%.0f USD",
            comment: "The formatted total budget for a Blaze campaign, fixed in USD. " +
            "Reads as $11 USD. Keep %.0f as is."
        )
        static let evergreenCampaignDate = NSLocalizedString(
            "blazeBudgetSettingViewModel.ongoingCampaignDate",
            value: "Ongoing from %1$@",
            comment: "The formatted date for an evergreen Blaze campaign, with the starting date in the placeholder. " +
            "Read as Starting from May 11."
        )
        static let weeklySpendAmount = NSLocalizedString(
            "blazeBudgetSettingViewModel.weeklySpendAmount",
            value: "%1$@ weekly spend",
            comment: "The total amount for weekly spend on the Blaze budget setting screen. " +
            "Reads like: $35 USD weekly spend"
        )
    }
}
