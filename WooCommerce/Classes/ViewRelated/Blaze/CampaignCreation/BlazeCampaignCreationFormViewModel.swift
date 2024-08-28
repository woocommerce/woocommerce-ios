import Foundation
import Experiments
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType
import struct Networking.BlazeAISuggestion
import Photos
import class Networking.UserAgent

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

    @Published private(set) var image: MediaPickerImage?
    @Published private(set) var tagline: String = "" {
        didSet {
            updateIsUsingAISuggestions()
        }
    }
    @Published private(set) var description: String = "" {
        didSet {
            updateIsUsingAISuggestions()
        }
    }

    // Whether the campaign should have no end date
    private var isEvergreen: Bool

    // Budget details
    private var startDate = Date.now + 60 * 60 * 24 // Current date + 1 day
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

    /// We need to recreate the view model every time the budget screen is opened to get the updated target options.
    lazy private(set) var budgetSettingViewModel: BlazeBudgetSettingViewModel = {
        BlazeBudgetSettingViewModel(siteID: siteID,
                                    dailyBudget: dailyBudget,
                                    isEvergreen: isEvergreen,
                                    duration: duration,
                                    startDate: startDate,
                                    targetOptions: targetOptions) { [weak self] dailyBudget, isEvergreen, duration, startDate in
            guard let self else { return }
            self.startDate = startDate
            self.isEvergreen = isEvergreen
            self.duration = duration
            self.dailyBudget = dailyBudget
            self.updateBudgetDetails()
        }
    }()

    var editAdViewModel: BlazeEditAdViewModel {
        let adData = BlazeEditAdData(image: image,
                                     tagline: tagline,
                                     description: description)
        return BlazeEditAdViewModel(siteID: siteID,
                                    productID: productID,
                                    adData: adData,
                                    suggestions: suggestions,
                                    onSave: { [weak self] adData in
            guard let self else { return }
            self.image = adData.image
            self.tagline = adData.tagline
            self.description = adData.description
        })
    }

    lazy private(set) var targetLanguageViewModel: BlazeTargetLanguagePickerViewModel = {
        BlazeTargetLanguagePickerViewModel(siteID: siteID, selectedLanguages: languages) { [weak self] selectedLanguages in
            self?.languages = selectedLanguages
            self?.updateTargetLanguagesText()
        }
    }()

    lazy private(set) var targetDeviceViewModel: BlazeTargetDevicePickerViewModel = {
        BlazeTargetDevicePickerViewModel(siteID: siteID, selectedDevices: devices) { [weak self] selectedDevices in
            self?.devices = selectedDevices
            self?.updateTargetDevicesText()
        }
    }()

    lazy private(set) var targetTopicViewModel: BlazeTargetTopicPickerViewModel = {
        BlazeTargetTopicPickerViewModel(siteID: siteID, selectedTopics: pageTopics) { [weak self] topics in
            self?.pageTopics = topics
            self?.updateTargetTopicText()
        }
    }()

    lazy private(set) var targetLocationViewModel: BlazeTargetLocationPickerViewModel = {
        BlazeTargetLocationPickerViewModel(siteID: siteID, selectedLocations: locations) { [weak self] locations in
            self?.locations = locations
            self?.updateTargetLocationText()
        }
    }()

    var confirmPaymentViewModel: BlazeConfirmPaymentViewModel? {
        guard let image else {
            return nil
        }
        return BlazeConfirmPaymentViewModel(productID: productID,
                                            siteID: siteID,
                                            campaignInfo: campaignInfo,
                                            image: image,
                                            onCompletion: { [weak self] in
            self?.completionHandler()
        })
    }

    lazy private(set) var adDestinationViewModel: BlazeAdDestinationSettingViewModel? = {
        // Only create viewModel (and thus show the ad destination setting) if these two URLs exist.
        guard let productURL, let siteURL else {
            DDLogError("Error: unable to create BlazeAdDestinationSettingViewModel because productURL and/or siteURL is empty.")
            return nil
        }
        return BlazeAdDestinationSettingViewModel(
            productURL: productURL,
            homeURL: siteURL,
            finalDestinationURL: finalDestinationURL) { [weak self] targetUrl, urlParams in
                guard let self else { return }
                self.targetUrl = targetUrl
                self.urlParams = urlParams
        }
    }()

    // For Ad destination purposes
    private var productURL: String? {
        if let product, let siteURL, product.permalink.isEmpty {
            /// fallback to the default product URL {site_url}?post_type=product&p={product_id}
            return product.alternativePermalink(with: siteURL)
        }
        return product?.permalink
    }
    private var siteURL: String? { stores.sessionManager.defaultSite?.url }

    @Published private(set) var budgetDetailText: String = ""
    @Published private(set) var targetLanguageText: String = ""
    @Published private(set) var targetDeviceText: String = ""
    @Published private(set) var targetTopicText: String = ""
    @Published private(set) var targetLocationText: String = ""

    // Ad destination URL
    @Published private var targetUrl: String = ""
    @Published private var urlParams: String = ""
    var finalDestinationURL: String {
        guard urlParams.isNotEmpty else {
            return targetUrl
        }

        return targetUrl + "?" + urlParams
    }

    // AI Suggestions
    @Published private(set) var isLoadingAISuggestions: Bool = false

    // Indicates whether AI suggestions are currently being used in the campaign creation form.
    @Published private(set) var isUsingAISuggestions: Bool = false

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

    @Published private var isLoadingProductImage: Bool = false

    var canEditAd: Bool {
        !isLoadingAISuggestions
    }

    var canConfirmDetails: Bool {
        tagline.isNotEmpty && description.isNotEmpty
    }

    @Published var isShowingMissingImageErrorAlert = false
    @Published var isShowingMissingDestinationURLAlert = false
    @Published var isShowingPaymentInfo = false

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

    private let targetUrn: String

    private var campaignBudgetInfo: BlazeCampaignBudget {
        // send daily budget for evergreen mode.
        BlazeCampaignBudget(mode: isEvergreen ? .daily : .total,
                            amount: isEvergreen ? dailyBudget : dailyBudget * Double(duration),
                            currency: Constants.defaultCurrency)
    }

    private var campaignInfo: CreateBlazeCampaign {
        CreateBlazeCampaign(origin: Constants.campaignOrigin,
                            originVersion: UserAgent.bundleShortVersion,
                            paymentMethodID: "", // to-be updated later on the payment screen
                            startDate: startDate,
                            endDate: startDate.addingTimeInterval(Constants.oneDayInSeconds * Double(duration)),
                            timeZone: TimeZone.current.identifier,
                            budget: campaignBudgetInfo,
                            isEvergreen: isEvergreen,
                            siteName: tagline,
                            textSnippet: description,
                            targetUrl: targetUrl,
                            urlParams: urlParams,
                            mainImage: CreateBlazeCampaign.Image(url: "", mimeType: ""), // Image info will be added by `BlazeConfirmPaymentViewModel`.
                            targeting: targetOptions,
                            targetUrn: targetUrn,
                            type: Constants.campaignType)
    }

    private let analytics: Analytics

    private var didTrackOnAppear = false

    init(siteID: Int64,
         productID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.productID = productID
        self.stores = stores
        self.storage = storage
        self.productImageLoader = productImageLoader
        self.analytics = analytics
        self.completionHandler = onCompletion
        self.targetUrn = String(format: Constants.targetUrnFormat, siteID, productID)

        // sets isEvergreen = true by default if evergreen campaigns are supported
        self.isEvergreen = featureFlagService.isFeatureFlagEnabled(.blazeEvergreenCampaigns)

        updateBudgetDetails()
        updateTargetLanguagesText()
        updateTargetDevicesText()
        updateTargetTopicText()
        updateTargetLocationText()
        initializeAdTargetUrl()
    }

    func onAppear() {
        // Track displayed event only once
        guard !didTrackOnAppear else {
            return
        }
        analytics.track(event: .Blaze.CreationForm.creationFormDisplayed())
        didTrackOnAppear = true
    }

    func onLoad() async {
        await withTaskGroup(of: Void.self) { group in
            if suggestions.isEmpty {
                group.addTask {
                    await self.loadAISuggestions()
                }
            }

            if image == nil {
                group.addTask {
                    await self.downloadProductImage()
                }
            }
        }
    }

    func didTapEditAd() {
        analytics.track(event: .Blaze.CreationForm.editAdTapped())
        onEditAd?()
    }

    @MainActor
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

    func didTapConfirmDetails() {
        guard image != nil else {
            return isShowingMissingImageErrorAlert = true
        }

        guard finalDestinationURL.isNotEmpty else {
            return isShowingMissingDestinationURLAlert = true
        }

        let taglineMatching = suggestions.map { $0.siteName }.contains { $0 == tagline }
        let descriptionMatching = suggestions.map { $0.textSnippet }.contains { $0 == description }
        let isAISuggestedAdContent = taglineMatching || descriptionMatching
        analytics.track(event: .Blaze.CreationForm.confirmDetailsTapped(
            isAISuggestedAdContent: isAISuggestedAdContent,
            isEvergreen: isEvergreen
        ))
        isShowingPaymentInfo = true
    }
}

// MARK: Image download
extension BlazeCampaignCreationFormViewModel {
    @MainActor
    func downloadProductImage() async {
        isLoadingProductImage = true
        if let productImage = await loadProductImage(),
           // Validate the image has expected dimensions
           productImage.image.size.width * productImage.image.scale >= editAdViewModel.minImageSize.width,
           productImage.image.size.height * productImage.image.scale >= editAdViewModel.minImageSize.height {
            image = productImage
        }
        isLoadingProductImage = false
    }
}

private extension BlazeCampaignCreationFormViewModel {
    func loadProductImage() async -> MediaPickerImage? {
        guard let firstImage = product?.images.first,
              let image = try? await productImageLoader.requestImage(productImage: firstImage) else {
            return nil
        }
        return .init(image: image, source: .productImage(image: firstImage))
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

    // Updates the `isUsingAISuggestions` property based on whether the current
    // `tagline` and `description` match any of the provided AI suggestions.
    // The property will be set to `true` if there is at least one suggestion
    // that matches both the `tagline` and `description`, and the suggestions list is not empty.
    func updateIsUsingAISuggestions() {
        isUsingAISuggestions = suggestions.contains { element in
            element.siteName == tagline && element.textSnippet == description && !suggestions.isEmpty
        }
    }

    enum FetchAISuggestionsError: Error {
        case suggestionsEmpty
    }
}

// MARK: - Private helpers

private extension BlazeCampaignCreationFormViewModel {
    func updateBudgetDetails() {
        let formattedStartDate = dateFormatter.string(for: startDate) ?? ""
        if isEvergreen {
            let weeklyAmount = String.localizedStringWithFormat(
                Localization.totalBudget,
                dailyBudget * Double(BlazeBudgetSettingViewModel.Constants.dayCountInWeek)
            )
            budgetDetailText = String(format: Localization.evergreenCampaignWeeklyBudget, weeklyAmount, formattedStartDate)
        } else {
            let amount = String.localizedStringWithFormat(Localization.totalBudget, dailyBudget * Double(duration))
            budgetDetailText = String.pluralize(
                duration,
                singular: String(format: Localization.budgetSingleDay, amount, duration, formattedStartDate),
                plural: String(format: Localization.budgetMultipleDays, amount, duration, formattedStartDate)
            )
        }
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

    func initializeAdTargetUrl() {
        // Default to promoting Product URL at the beginning.
        if let productURL = productURL {
            targetUrl = productURL
        }
    }
}

extension BlazeCampaignCreationFormViewModel {
    enum BlazeCampaignCreationError: Error {
        case failedToLoadAISuggestions
    }
}

private extension BlazeCampaignCreationFormViewModel {
    enum Constants {
        /// origin the of the created campaign, used for analytics.
        static let campaignOrigin = "wc-ios"
        /// We are supporting product promotion only for now.
        static let campaignType = "product"
        static let oneDayInSeconds: Double = 86400
        static let targetUrnFormat = "urn:wpcom:post:%d:%d"
        static let defaultCurrency = "USD"
    }
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
        static let evergreenCampaignWeeklyBudget = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.evergreenCampaignWeeklyBudget",
            value: "%1$@ weekly starting from %2$@",
            comment: "The formatted weekly budget for an evergreen Blaze campaign with a starting date. " +
            "Reads as $11 USD weekly starting from May 11 2024."
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
