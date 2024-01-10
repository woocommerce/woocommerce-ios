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

    @Published private(set) var isDownloadingImage: Bool = true
    var productImage: URL? {
        product?.imageURL
    }
    @Published private(set) var image: MediaPickerImage = .init(image: .blazeProductPlaceholder, source: .memory)
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

    var editAdViewModel: BlazeEditAdViewModel {
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

    @Published private(set) var errorState: ErrorState = .none
    private var suggestions: [BlazeAISuggestion] = []

    var canConfirmDetails: Bool {
        guard !isDownloadingImage else {
            return false
        }
        return tagline.isNotEmpty && description.isNotEmpty
    }

    /// ResultController to to track the current product count.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = \StorageProduct.siteID == siteID && \StorageProduct.productID == productID
        let controller = ResultsController<StorageProduct>(storageManager: storage, matching: predicate, sortedBy: [])
        try? controller.performFetch()
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
    }

    func didTapEditAd() {
        onEditAd?()
    }

    func loadAISuggestions() async {
        isLoadingAISuggestions = true
        errorState = .none

        do {
            suggestions = try await fetchAISuggestions()
            if let firstSuggestion = suggestions.first {
                tagline = firstSuggestion.siteName
                description = firstSuggestion.textSnippet
            }
        } catch {
            DDLogError("⛔️ Error fetching Blaze AI suggestions: \(error)")
            errorState = .fetchingAISuggestions
        }

        isLoadingAISuggestions = false
    }

    func downloadProductImage() async {
        isDownloadingImage = true
        if let productImage = await loadProductImage() {
            image = productImage
        }
        isDownloadingImage = false
    }
}

private extension BlazeCampaignCreationFormViewModel {
    func loadProductImage() async -> MediaPickerImage? {
        await withCheckedContinuation({ continuation in
            guard let firstImage = product?.images.first else {
                return continuation.resume(returning: nil)
            }
            _ = productImageLoader.requestImage(productImage: firstImage) { image in
                continuation.resume(returning: .init(image: image, source: .memory))
            }
        })
    }

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

// MARK: - Blaze AI Suggestions
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

extension BlazeCampaignCreationFormViewModel {
    enum ErrorState: Equatable {
        case none
        case fetchingAISuggestions

        var errorMessage: String {
            switch self {
            case .none:
                return ""
            case .fetchingAISuggestions:
                return Localization.ErrorMessage.fetchingAISuggestions
            }
        }
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
        enum ErrorMessage {
            static let fetchingAISuggestions = NSLocalizedString(
                "blazeCampaignCreationFormViewModel.fetchingAISuggestions",
                value: "Failed to load suggestions for tagline and description",
                comment: "Error message indicating that loading suggestions for tagline and description failed"
            )
        }
    }
}
