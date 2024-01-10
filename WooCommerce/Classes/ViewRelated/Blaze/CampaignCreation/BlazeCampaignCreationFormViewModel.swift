import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType
import struct Networking.BlazeAISuggestion
import Photos

/// View model for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormViewModel: ObservableObject {

    let siteID: Int64
    private let productID: Int64
    private let stores: StoresManager
    private let productImageLoader: ProductUIImageLoader
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

    // Target options
    private(set) var locations: Set<BlazeTargetLocation>?
    private(set) var languages: Set<BlazeTargetLanguage>?
    private(set) var devices: Set<BlazeTargetDevice>?
    private(set) var pageTopics: Set<BlazeTargetTopic>?

    var targetOptions: BlazeTargetOptions? {
        guard locations != nil || languages != nil || devices != nil || pageTopics != nil else {
            return nil
        }
        return BlazeTargetOptions(locations: locations?.map { $0.id },
                                  languages: languages?.map { $0.id },
                                  devices: devices?.map { $0.id },
                                  pageTopics: pageTopics?.map { $0.id })
    }

    var budgetSettingViewModel: BlazeBudgetSettingViewModel {
        BlazeBudgetSettingViewModel(siteID: siteID,
                                    dailyBudget: dailyBudget,
                                    duration: duration,
                                    startDate: startDate,
                                    targetOptions: targetOptions) { [weak self] dailyBudget, duration, startDate in
            guard let self else { return }
            self.startDate = startDate
            self.duration = duration
            self.dailyBudget = dailyBudget
            self.updateBudgetDetails()
        }
    }

    var editAdViewModel: BlazeEditAdViewModel {
        // TODO: Send ad data to edit screen
        let adData = BlazeEditAdData(image: .init(image: .blazeIntroIllustration, source: .asset(asset: .init())),
                                     tagline: "From $99",
                                     description: "Get the latest white shirt for a stylish look")
        // TODO: Send suggestions to edit screen
        let suggestions = {
            var suggestions = [BlazeAISuggestion]()
            for i in 0..<3 {
                suggestions.append(BlazeAISuggestion(siteName: "Tagline \(i+1)",
                                                     textSnippet: "Description \(i+1)"))
            }
            return suggestions
        }()
        return BlazeEditAdViewModel(siteID: siteID,
                                    adData: adData,
                                    suggestions: suggestions,
                                    onSave: { _ in
            // TODO: Update ad with edited data
        })
    }

    var targetLanguageViewModel: BlazeTargetLanguagePickerViewModel {
        BlazeTargetLanguagePickerViewModel(siteID: siteID) { [weak self] selectedLanguages in
            self?.languages = selectedLanguages
            self?.updateTargetLanguagesText()
        }
    }

    var targetDeviceViewModel: BlazeTargetDevicePickerViewModel {
        BlazeTargetDevicePickerViewModel(siteID: siteID) { [weak self] selectedDevices in
            self?.devices = selectedDevices
            self?.updateTargetDevicesText()
        }
    }

    @Published private(set) var budgetDetailText: String = ""
    @Published private(set) var targetLanguageText: String = ""
    @Published private(set) var targetDeviceText: String = ""

    init(siteID: Int64,
         productID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
    productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.productID = productID
        self.stores = stores
        self.storage = storage
        self.productImageLoader = productImageLoader
        self.completionHandler = onCompletion

        updateBudgetDetails()
        updateTargetLanguagesText()
        updateTargetDevicesText()
    }

    func didTapEditAd() {
        onEditAd?()
    }
}

private extension BlazeCampaignCreationFormViewModel {
    func updateBudgetDetails() {
        let amount = String.localizedStringWithFormat(Localization.totalBudget, dailyBudget * Double(duration))
        let date = dateFormatter.string(for: startDate) ?? ""
        budgetDetailText = String.pluralize(
            duration,
            singular: String(format: Localization.budgetSingleDay, amount, duration, date),
            plural: String(format: Localization.budgetMultipleDays, amount, duration, date)
        )
    }

    func updateTargetLanguagesText() {
        targetLanguageText = {
            guard let languages, languages.isEmpty == false else {
                return Localization.all
            }
            return languages
                .map { $0.name }
                .sorted()
                .joined(separator: ", ")
        }()
    }

    func updateTargetDevicesText() {
        targetDeviceText = {
            guard let devices, devices.isEmpty == false else {
                return Localization.all
            }
            return devices
                .map { $0.name }
                .sorted()
                .joined(separator: ", ")
        }()
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
        static let totalBudget = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.totalBudget",
            value: "$%.0f USD",
            comment: "The formatted total budget for a Blaze campaign, fixed in USD. " +
            "Reads as $11 USD. Keep %.0f as is."
        )
        static let all = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.all",
            value: "All",
            comment: "Text indicating all targets for a Blaze campaign"
        )
    }
}
