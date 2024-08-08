import UIKit
import Yosemite
import Combine
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `BlazeCampaignDashboardView`.
@MainActor
final class BlazeCampaignDashboardViewModel: ObservableObject {
    /// UI state of the Blaze campaign view in dashboard.
    enum State: Equatable {
        /// Shows placeholder views in redacted state.
        case loading
        /// Shows info about the latest Blaze campaign
        case showCampaign(campaign: BlazeCampaignListItem)
        /// Shows info about the latest published Product
        case showProduct(product: Product)
        /// When there is no campaign or published product
        case empty
    }

    @Published private(set) var state: State

    @Published private(set) var canShowInDashboard = false

    var shouldShowIntroView: Bool {
        blazeCampaignResultsController.numberOfObjects == 0
    }

    @Published var selectedCampaignURL: URL?

    private(set) var shouldRedactView: Bool = true

    var shouldShowShowAllCampaignsButton: Bool {
        if case .showCampaign = state {
            return true
        } else {
            return false
        }
    }

    var shouldShowCreateCampaignButton: Bool {
        if case .empty = state {
            return false
        }
        return true
    }

    var shouldShowSubtitle: Bool {
        switch state {
        case .showCampaign, .empty:
            return false
        case .loading, .showProduct:
            return true
        }
    }

    /// Set externally in the hosting controller to invalidate the SwiftUI `BlazeCampaignDashboardView`'s intrinsic content size as a workaround with UIKit.
    var onStateChange: (() -> Void)?

    /// Set externally to trigger when dismissing the card.
    var onDismiss: (() -> Void)?

    let siteID: Int64

    var siteURL: String {
        stores.sessionManager.defaultSite?.url ?? ""
    }

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    private var isSiteEligibleForBlaze = false
    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol

    /// Blaze campaign ResultsController.
    private lazy var blazeCampaignResultsController: ResultsController<StorageBlazeCampaignListItem> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(key: "campaignID",
                                                  ascending: false,
                                                  selector: #selector(NSString.localizedStandardCompare))
        let resultsController = ResultsController<StorageBlazeCampaignListItem>(storageManager: storageManager,
                                                                                matching: predicate,
                                                                                fetchLimit: 1,
                                                                                sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    /// Product ResultsController.
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld AND statusKey ==[c] %@",
                                    siteID,
                                    ProductStatus.published.rawValue)
        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 fetchLimit: 1,
                                                 sortOrder: .dateDescending)
    }()

    var latestPublishedProduct: Product? {
        productResultsController.fetchedObjects.first
    }

    private var subscriptions: Set<AnyCancellable> = []

    @Published private var syncingError: Error?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker()) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.blazeEligibilityChecker = blazeEligibilityChecker
        self.state = .loading
        observeSectionVisibility()
        configureResultsController()
    }

    @MainActor
    func checkAvailability() async {
        isSiteEligibleForBlaze = await checkSiteEligibility()
        try? await synchronizePublishedProducts()
        updateAvailability()
    }

    @MainActor
    func reload() async {
        syncingError = nil
        update(state: .loading)

        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .blaze))

        isSiteEligibleForBlaze = await checkSiteEligibility()

        guard isSiteEligibleForBlaze else {
            update(state: .empty)
            return
        }

        do {
            // Load Blaze campaigns
            try await synchronizeBlazeCampaigns()

            // Load all products
            // In case there are no campaigns, this helps decide whether to show a Product on the Blaze dashboard.
            // It also helps determine whether the "Promote" button opens to product selector first (if the site has multiple
            // products) or straight to campaign creation form (if there is only one product).
            try await synchronizePublishedProducts()
        } catch {
            syncingError = error
        }

        trackSyncingResult()
        updateResults()
    }

    func didTapCreateYourCampaignButtonFromIntroView() {
        analytics.track(event: .Blaze.blazeEntryPointTapped(source: .introView))
    }

    func didSelectCampaignList() {
        analytics.track(event: .Blaze.blazeCampaignListEntryPointSelected(source: .myStoreSection))
    }

    func didSelectCampaignDetails(_ campaign: BlazeCampaignListItem) {
        analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .blaze))
        analytics.track(event: .Blaze.blazeCampaignDetailSelected(source: .myStoreSection))

        let path = String(format: Constants.campaignDetailsURLFormat,
                          campaign.campaignID,
                          siteURL.trimHTTPScheme(),
                          BlazeCampaignDetailSource.myStoreSection.rawValue)
        selectedCampaignURL = URL(string: path)
    }

    func didSelectCreateCampaign(source: BlazeSource) {
        analytics.track(event: .Blaze.blazeEntryPointTapped(source: source))
    }

    func dismissBlazeSection() {
        onDismiss?()
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .blaze))
        analytics.track(event: .Blaze.blazeViewDismissed(source: .myStoreSection))
    }

    func didCreateCampaign() {
        Task {
            await reload()
        }
    }
}

// MARK: - Blaze campaigns
private extension BlazeCampaignDashboardViewModel {
    func checkSiteEligibility() async -> Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }
        return await blazeEligibilityChecker.isSiteEligible(site)
    }

    @MainActor
    func synchronizeBlazeCampaigns() async throws {
        try await withCheckedThrowingContinuation({ continuation in
            stores.dispatch(BlazeAction.synchronizeCampaignsList(siteID: siteID,
                                                                  skip: 0,
                                                                  limit: PaginationTracker.Defaults.pageSize) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    DDLogError("⛔️ Dashboard — Error synchronizing Blaze campaigns: \(error)")
                    continuation.resume(throwing: error)
                }
            })
        })
    }
}


// MARK: - Products
private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func synchronizePublishedProducts() async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.synchronizeProducts(siteID: siteID,
                                                              pageNumber: Store.Default.firstPageNumber,
                                                              stockStatus: nil,
                                                              productStatus: .published,
                                                              productType: nil,
                                                              productCategory: nil,
                                                              sortOrder: .dateDescending,
                                                              shouldDeleteStoredProductsOnFirstPage: false,
                                                              onCompletion: { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    DDLogError("⛔️ Dashboard — Error fetching first published product to show the Blaze campaign view: \(error)")
                    continuation.resume(throwing: error)
                }
            }))
        }
    }
}

// MARK: - Helpers
private extension BlazeCampaignDashboardViewModel {
    func update(state: State) {
        self.state = state
        switch state {
        case .loading:
            shouldRedactView = true
        case .showCampaign, .showProduct:
            shouldRedactView = false
        case .empty:
            shouldRedactView = true
        }
        onStateChange?()
    }

    func updateAvailability() {
        canShowInDashboard = isSiteEligibleForBlaze && latestPublishedProduct != nil
    }

    func updateResults() {
        guard isSiteEligibleForBlaze else {
            return update(state: .empty)
        }

        if let campaign = blazeCampaignResultsController.fetchedObjects.first {
            update(state: .showCampaign(campaign: campaign))
        } else if let product = latestPublishedProduct {
            update(state: .showProduct(product: product))
        } else {
            update(state: .empty)
        }
    }

    /// Performs initial fetch from storage and updates results.
    func configureResultsController() {
        blazeCampaignResultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        blazeCampaignResultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }

        productResultsController.onDidChangeContent = { [weak self] in
            self?.updateAvailability()
            self?.updateResults()
        }
        productResultsController.onDidResetContent = { [weak self] in
            self?.updateAvailability()
            self?.updateResults()
        }

        do {
            try blazeCampaignResultsController.performFetch()
            try productResultsController.performFetch()
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func observeSectionVisibility() {
        $state
            .map { state in
                switch state {
                case .showCampaign, .showProduct:
                    return true
                default:
                    return false
                }
            }
            .filter { $0 }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.analytics.track(event: .Blaze.blazeEntryPointDisplayed(source: .myStoreSection))
            }
            .store(in: &subscriptions)
    }

    func trackSyncingResult() {
        if let syncingError {
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .blaze, error: syncingError))
        } else {
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .blaze))
        }
    }
}

private extension BlazeCampaignDashboardViewModel {
    enum Constants {
        static let campaignDetailsURLFormat = "https://wordpress.com/advertising/campaigns/%@/%@?source=%@"
    }
}
