import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType
import struct Networking.BlazeAISuggestion
import Photos

/// View model for `BlazeCampaignCreationForm`
@MainActor
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

    var productImage: URL? {
        product?.imageURL
    }
    @Published private(set) var image: MediaPickerImage?
    @Published private(set) var tagline: String = ""
    @Published private(set) var description: String = ""

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

    var editAdViewModel: BlazeEditAdViewModel? {
        guard let image else {
            assertionFailure("Product image is not downloaded. Edit ad button should be disabled.")
            return nil
        }
        let adData = BlazeEditAdData(image: image,
                                     tagline: tagline,
                                     description: description)
        return BlazeEditAdViewModel(siteID: siteID,
                                    adData: adData,
                                    suggestions: suggestions,
                                    onSave: { [weak self] adData in
            guard let self else { return }
            self.image = adData.image
            self.tagline = adData.tagline
            self.description = adData.description
        })
    }

    var targetLanguageViewModel: BlazeTargetLanguagePickerViewModel {
        BlazeTargetLanguagePickerViewModel(siteID: siteID, selectedLanguages: languages) { [weak self] selectedLanguages in
            self?.languages = selectedLanguages
            self?.updateTargetLanguagesText()
        }
    }

    var targetDeviceViewModel: BlazeTargetDevicePickerViewModel {
        BlazeTargetDevicePickerViewModel(siteID: siteID, selectedDevices: devices) { [weak self] selectedDevices in
            self?.devices = selectedDevices
            self?.updateTargetDevicesText()
        }
    }

    var targetTopicViewModel: BlazeTargetTopicPickerViewModel {
        BlazeTargetTopicPickerViewModel(siteID: siteID, selectedTopics: pageTopics) { [weak self] topics in
            self?.pageTopics = topics
            self?.updateTargetTopicText()
        }
    }

    var targetLocationViewModel: BlazeTargetLocationPickerViewModel {
        BlazeTargetLocationPickerViewModel(siteID: siteID, selectedLocations: locations) { [weak self] locations in
            self?.locations = locations
            self?.updateTargetLocationText()
        }
    }

    @Published private(set) var budgetDetailText: String = ""
    @Published private(set) var targetLanguageText: String = ""
    @Published private(set) var targetDeviceText: String = ""
    @Published private(set) var targetTopicText: String = ""
    @Published private(set) var targetLocationText: String = ""

    // AI Suggestions
    @Published private(set) var isLoadingAISuggestions: Bool = true
    private let storage: StorageManagerType
    private var product: Product? {
        guard let product = productsResultsController.fetchedObjects.first else {
            assertionFailure("Unable to fetch product with ID: \(productID)")
            return nil
        }
        return product
    }

    @Published private(set) var error: BlazeCampaignCreationError?
    private var suggestions: [BlazeAISuggestion] = []

    var canEditAd: Bool {
        image != nil && !isLoadingAISuggestions
    }

    var canConfirmDetails: Bool {
        image != nil && tagline.isNotEmpty && description.isNotEmpty
    }

    /// ResultController to get the product for the given product ID
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = \StorageProduct.siteID == siteID && \StorageProduct.productID == productID
        let controller = ResultsController<StorageProduct>(storageManager: storage, matching: predicate, sortedBy: [])
        do {
            try controller.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch product for BlazeCampaignCreationFormViewModel: \(error)")
        }
        return controller
    }()

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
        updateTargetTopicText()
        updateTargetLocationText()
    }

    func didTapEditAd() {
        onEditAd?()
    }
}

// MARK: Image download
extension BlazeCampaignCreationFormViewModel {
    func downloadProductImage() async {
        image = await loadProductImage()
    }
}

private extension BlazeCampaignCreationFormViewModel {
    func loadProductImage() async -> MediaPickerImage? {
        await withCheckedContinuation({ continuation in
            guard let firstImage = product?.images.first else {
                return continuation.resume(returning: nil)
            }
            _ = productImageLoader.requestImage(productImage: firstImage) { image in
                continuation.resume(returning: .init(image: image, source: .productImage(image: firstImage)))
            }
        })
    }
}

// MARK: - Blaze AI Suggestions
extension BlazeCampaignCreationFormViewModel {
    func loadAISuggestions() async {
        isLoadingAISuggestions = true
        error = nil

        do {
            suggestions = try await fetchAISuggestions()
            if let firstSuggestion = suggestions.first {
                tagline = firstSuggestion.siteName
                description = firstSuggestion.textSnippet
            }
        } catch {
            DDLogError("⛔️ Error fetching Blaze AI suggestions: \(error)")
            self.error = .failedToLoadAISuggestions
        }

        isLoadingAISuggestions = false
    }
}

private extension BlazeCampaignCreationFormViewModel {
    @MainActor
    func fetchAISuggestions() async throws -> [BlazeAISuggestion] {
        try await withCheckedThrowingContinuation({ continuation in
            stores.dispatch(BlazeAction.fetchAISuggestions(siteID: siteID, productID: productID) { result in
                switch result {
                case .success(let suggestions):
                    if suggestions.isEmpty {
                        continuation.resume(throwing: FetchAISuggestionsError.suggestionsEmpty)
                    } else {
                        continuation.resume(returning: suggestions)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        })
    }

    enum FetchAISuggestionsError: Error {
        case suggestionsEmpty
    }
}

// MARK: - Private helpers

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

    func updateTargetTopicText() {
        targetTopicText = {
            guard let pageTopics, pageTopics.isEmpty == false else {
                return Localization.all
            }
            return pageTopics
                .map { $0.name }
                .sorted()
                .joined(separator: ", ")
        }()
    }

    func updateTargetLocationText() {
        targetLocationText = {
            guard let locations, locations.isEmpty == false else {
                return Localization.everywhere
            }
            return locations
                .map { $0.name }
                .sorted()
                .joined(separator: ", ")
        }()
    }
}

extension BlazeCampaignCreationFormViewModel {
    enum BlazeCampaignCreationError: Error {
        case failedToLoadAISuggestions
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
        static let everywhere = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.everywhere",
            value: "Everywhere",
            comment: "Text indicating all locations for a Blaze campaign"
        )
    }
}
