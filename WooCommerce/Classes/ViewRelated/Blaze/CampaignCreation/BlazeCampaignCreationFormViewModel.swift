import Foundation
import Yosemite

/// View model for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormViewModel: ObservableObject {

    let siteID: Int64
    private let stores: StoresManager
    private let completionHandler: () -> Void
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()

    var onEditAd: (() -> Void)?

    // Budget details
    private var startDate = Date.now
    private var dailyBudget = BlazeBudgetSettingViewModel.Constants.minimumDailyAmount
    private var duration = BlazeBudgetSettingViewModel.Constants.defaultDayCount

    var budgetSettingViewModel: BlazeBudgetSettingViewModel {
        BlazeBudgetSettingViewModel(dailyBudget: dailyBudget, duration: duration, startDate: startDate) { [weak self] dailyBudget, duration, startDate in
            guard let self else { return }
            self.startDate = startDate
            self.duration = duration
            self.dailyBudget = dailyBudget
            self.updateBudgetDetails()
        }
    }

    @Published private(set) var budgetDetailText: String = ""

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.completionHandler = onCompletion

        updateBudgetDetails()
    }

    func didTapEditAd() {
        onEditAd?()
    }
}

private extension BlazeCampaignCreationFormViewModel {
    func updateBudgetDetails() {
        let amount = String(format: "$%.0f USD", dailyBudget * Double(duration))
        let date = dateFormatter.string(for: startDate) ?? ""
        budgetDetailText = String.pluralize(
            duration,
            singular: String(format: Localization.budgetSingleDay, amount, duration, date),
            plural: String(format: Localization.budgetMultipleDays, amount, duration, date)
        )
    }
}

private extension BlazeCampaignCreationFormViewModel {
    enum Localization {
        static let budgetSingleDay = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.budgetSingleDay",
            value: "%1$@, %2$d day from %3$@",
            comment: "Blaze campaign budget details with duration in singular form. " +
            "Reads like: $35, 1 day from Dec 31"
        )
        static let budgetMultipleDays = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.budgetMultipleDays",
            value: "%1$@, %2$d days from %3$@",
            comment: "Blaze campaign budget details with duration in plural form. " +
            "Reads like: $35, 15 days from Dec 31"
        )
    }
}
