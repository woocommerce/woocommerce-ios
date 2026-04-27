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
    @Published private(set) var ctaText: String = "" {
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

    private var campaignObjective: BlazeCampaignObjective?

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
                                     description: description,
                                     ctaText: ctaText)
        return BlazeEditAdViewModel(siteID: siteID,
                                    productID: productID,
                                    adData: adData,
                                    suggestions: suggestions,
                                    isUsingAISuggestions: isUsingAISuggestions,
                                    onSave: { [weak self] adData in
            guard let self else { return }
            self.image = adData.image
            self.tagline = adData.tagline
            self.description = adData.description
            self.ctaText = adData.ctaText
        })
    }

    lazy private(set) var campaignObjectiveViewModel: BlazeCampaignObjectivePickerViewModel = {
        BlazeCampaignObjectivePickerViewModel(siteID: siteID, selectedObjective: campaignObjective) { [weak self] selectedObjective in
            self?.campaignObjective = selectedObjective
            self?.campaignObjectiveText = selectedObjective?.title
        }
    }()

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

    @Published private(set) var campaignObjectiveText: String?
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
    private var product: BlazeCampaignProduct?

    @Published private(set) var error: BlazeCampaignCreationError?
    private var suggestions: [BlazeAISuggestion] = []

    @Published private(set) var isLoadingProductImage: Bool = true

    var canEditAd: Bool {
        !isLoadingAISuggestions
    }

    var canConfirmDetails: Bool {
        tagline.isNotEmpty && description.isNotEmpty && isToSAccepted
    }

    @Published var isToSAccepted = false
    @Published var isShowingMissingObjectiveAlert = false
    @Published var isShowingMissingImageErrorAlert = false
    @Published var isShowingMissingDestinationURLAlert = false
    @Published var isShowingPaymentInfo = false

    /// ResultController to get the product for the given product ID
    ///
    private lazy var productsResultsController: GenericResultsController<StorageProduct, BlazeCampaignProduct> = {
        let predicate = \StorageProduct.siteID == siteID && \StorageProduct.productID == productID
        let controller = GenericResultsController<StorageProduct, BlazeCampaignProduct>(
            storageManager: storage,
            matching: predicate,
            sortedBy: [],
            transformer: { BlazeCampaignProduct(storageProduct: $0) }
        )
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
                            type: Constants.campaignType,
                            objective: campaignObjective?.id,
                            ctaText: ctaText,
                            acceptedTOS: true)
    }

    private let locale: Locale
    private let userDefaults: UserDefaults
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService

    private var didTrackOnAppear = false

    init(siteID: Int64,
         productID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         locale: Locale = .current,
         userDefaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.productID = productID
        self.stores = stores
        self.storage = storage
        self.productImageLoader = productImageLoader
        self.locale = locale
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.completionHandler = onCompletion
        self.targetUrn = String(format: Constants.targetUrnFormat, siteID, productID)

        // sets isEvergreen = true by default if evergreen campaigns are supported
        self.isEvergreen = featureFlagService.isFeatureFlagEnabled(.blazeEvergreenCampaigns)

        product = productsResultsController.fetchedObjects.first

        initializeCampaignObjective()
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
            // Make sure AI Suggestions are called just if suggestions are empty, and we didn't already populated tagline, description and ctaText.
            if suggestions.isEmpty && tagline.isEmpty && description.isEmpty && ctaText.isEmpty {
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
                ctaText = firstSuggestion.ctaText
            }
        } catch {
            if let productName = product?.name, let productDescription = product?.shortDescription ?? product?.fullDescription {
                tagline = productName
                description = productDescription
                ctaText = Localization.shopNow
            }
            DDLogError("⛔️ Error fetching Blaze AI suggestions: \(error)")
            analytics.track(event: .Blaze.CreationForm.suggestionLoadingFailed(error: error))
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

        if featureFlagService.isFeatureFlagEnabled(.blazeCampaignObjective),
           campaignObjective == nil {
            return isShowingMissingObjectiveAlert = true
        }

        let taglineMatching = suggestions.map { $0.siteName }.contains { $0 == tagline }
        let descriptionMatching = suggestions.map { $0.textSnippet }.contains { $0 == description }
        let isAISuggestedAdContent = taglineMatching || descriptionMatching
        analytics.track(event: .Blaze.CreationForm.confirmDetailsTapped(
            isAISuggestedAdContent: isAISuggestedAdContent,
            isEvergreen: isEvergreen,
            objective: campaignObjective?.id
        ))
        isShowingPaymentInfo = true
    }
}

// MARK: Duration type

private extension BlazeCampaignCreationFormViewModel {
    enum BlazeCampaignDuration {
        case upToSevenDays
        case moreThanSevenDays
        case evergreen

        var tosCheckboxFirstLineLocalizedFormat: String {
            switch self {
            case .evergreen:
                return Localization.tosCheckboxFirstLinePartEvergreen
            case .upToSevenDays:
                return Localization.tosCheckboxFirstLinePartUpToSevenDays
            case .moreThanSevenDays:
                return Localization.tosCheckboxFirstLinePartMoreThanSevenDays
            }
        }
    }

    var campaignDuration: BlazeCampaignDuration {
        if isEvergreen {
            return .evergreen
        } else if duration <= 7 {
            return .upToSevenDays
        } else {
            return .moreThanSevenDays
        }
    }
}

// MARK: TOS checkbox
extension BlazeCampaignCreationFormViewModel {
    private var weeklyAmount: Double {
        return dailyBudget * Double(BlazeBudgetSettingViewModel.Constants.dayCountInWeek)
    }

    var tosCheckboxAttributedText: AttributedString {
        return tosCheckboxFirstLineAttributedText() +
        AttributedString(" ") +
        tosCheckboxSecondLineAttributedText()
    }

    private func tosCheckboxFirstLineAttributedText() -> AttributedString {
        // Create the first line as AttributedString with bold formatting
        let firstLineString = String.localizedStringWithFormat(
            campaignDuration.tosCheckboxFirstLineLocalizedFormat,
            weeklyAmount,
            dateFormatter.string(for: startDate) ?? ""
        )

        let firstLineElements = BoldableTextParser().parseBoldableElements(string: firstLineString)
        var firstLineAttributed = AttributedString()
        for element in firstLineElements {
            var elementText = AttributedString(element.content)
            elementText.font = .body
            elementText.foregroundColor = .init(.text)
            if element.isBold {
                elementText.font = .body.bold()
            }
            firstLineAttributed += elementText
        }

        return firstLineAttributed
    }

    private func tosCheckboxSecondLineAttributedText() -> AttributedString {
        return AttributedString.withEmbeddedLink(
            mainContent: Localization.tosCheckboxSecondLinePart,
            linkText: Localization.campaignDetailsLinkText,
            link: Links.stopAnAdCampaign
        )
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
    @MainActor
    func loadProductImage() async -> MediaPickerImage? {
        guard let firstImage = product?.firstImage,
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
    // that matches both the `tagline` and `description`.
    func updateIsUsingAISuggestions() {
        isUsingAISuggestions = suggestions.contains { element in
            element.siteName == tagline && element.textSnippet == description && element.ctaText == ctaText
        }
    }

    enum FetchAISuggestionsError: Error {
        case suggestionsEmpty
    }
}

// MARK: - Private helpers

private extension BlazeCampaignCreationFormViewModel {
    func initializeCampaignObjective() {
        guard featureFlagService.isFeatureFlagEnabled(.blazeCampaignObjective) else {
            return
        }
        guard let savedID = userDefaults.retrieveSavedObjectiveID(for: siteID) else {
            return
        }
        let objective = storage.viewStorage.retrieveBlazeCampaignObjective(id: savedID, locale: locale.identifier)
        guard let readOnlyObjective = objective?.toReadOnly() else {
            return
        }
        campaignObjective = readOnlyObjective
        campaignObjectiveText = readOnlyObjective.title
    }

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
        if let productURL {
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
    enum Links {
        static let stopAnAdCampaign = "https://wordpress.com/support/promote-a-post/manage-your-blaze-ad-campaign/#stop-an-ad-campaign"
    }
    enum Localization {
        static let budgetSingleDay = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.budgetSingleDay",
            value: "%1$@, %2$d day from %3$@",
            comment: "Blaze campaign budget details with duration in singular form. " +
            "Reads like: $35, 1 day from Dec 31"
        )
        static let shopNow = NSLocalizedString(
            "blazeCampaignCreationForm.shopNow",
            value: "Shop Now",
            comment: "Button to shop on the Blaze ad preview"
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

        static let tosCheckboxFirstLinePartUpToSevenDays = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.tosCheckboxFirstLinePart.upToSevenDays",
            value: "I agree to be charged up to **$%1$.0f** starting **%2$@**. Charges may occur in one or more payments while the campaign is active.",
            comment: "First part of checkbox text for accepting terms of service for finite Blaze campaigns with the duration up to 7 days. " +
            "%1$.0f is the weekly budget amount, %2$@ is the formatted start date. The content inside two double asterisks **...** denote bolded text."
        )

        static let tosCheckboxFirstLinePartMoreThanSevenDays = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.tosCheckboxFirstLinePart.MoreThanSevenDays",
            value: "I agree to a recurring charge of up to **$%1$.0f weekly** starting **%2$@**. Charges may occur at varying times during the campaign.",
            comment: "First part of checkbox text for accepting terms of service for finite Blaze campaigns with the duration of more than 7 days. " +
            "%1$.0f is the weekly budget amount, %2$@ is the formatted start date. The content inside two double asterisks **...** denote bolded text."
        )

        static let tosCheckboxFirstLinePartEvergreen = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.tosCheckboxFirstLinePartEvergreen",
            value: "I agree to a recurring **weekly charge up to $%1$.0f** starting **%2$@**. Charges may occur at varying times during the campaign.",
            comment: "First part of checkbox text for accepting terms of service for the endless Blaze campaign subscription. " +
            "%1$.0f is the weekly budget amount, %2$@ is the formatted start date. The content inside two double asterisks **...** denote bolded text."
        )

        static let tosCheckboxSecondLinePart = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.tosCheckboxSecondLinePart",
            value: "%@; I’ll only pay for ads delivered up to cancellation.",
            comment: "Second part of checkbox text for accepting terms of service for finite Blaze campaigns. " +
            "%@ is \"I can cancel anytime\" substring for a hyperlink."
        )

        static let campaignDetailsLinkText = NSLocalizedString(
            "blazeCampaignCreationFormViewModel.campaignDetailsLinkText",
            value: "I can cancel anytime",
            comment: "Text that will become a hyperlink in the second line of the terms of service checkbox text."
        )
    }
}
