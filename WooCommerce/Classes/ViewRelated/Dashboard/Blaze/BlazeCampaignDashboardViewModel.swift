import UIKit
import Yosemite
import Combine
import protocol Storage.StorageManagerType

/// View model for `BlazeCampaignDashboardView`.
final class BlazeCampaignDashboardViewModel: ObservableObject {
    /// UI state of the Blaze campaign view in dashboard.
    enum State: Equatable {
        /// Shows placeholder views in redacted state.
        case loading
        /// Shows info about the latest Blaze campaign
        case showCampaign(campaign: BlazeCampaign)
        /// Shows info about the latest published Product
        case showProduct(product: Product)
        /// When there is no campaign or published product
        case empty
    }

    @Published private(set) var state: State

    @Published private(set) var shouldShowInDashboard: Bool = false

    @Published var shouldShowIntroView: Bool = false {
        didSet {
            if shouldShowIntroView {
                analytics.track(event: .Blaze.blazeEntryPointDisplayed(source: .introView))
            }
        }
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

    /// Set externally in the hosting controller to invalidate the SwiftUI `BlazeCampaignDashboardView`'s intrinsic content size as a workaround with UIKit.
    var onStateChange: (() -> Void)?

    let siteID: Int64
    let siteURL: String
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol
    private let userDefaults: UserDefaults

    /// Blaze campaign ResultsController.
    private lazy var blazeCampaignResultsController: ResultsController<StorageBlazeCampaign> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeCampaign.campaignID, ascending: false)
        let resultsController = ResultsController<StorageBlazeCampaign>(storageManager: storageManager,
                                                                        matching: predicate,
                                                                        fetchLimit: 1,
                                                                        sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    /// Product ResultsController.
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld AND statusKey ==[c] %@ ", siteID, ProductStatus.published.rawValue)
        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 fetchLimit: 1,
                                                 sortOrder: .dateDescending)
    }()

    private var latestPublishedProduct: Product? {
        productResultsController.fetchedObjects.first
    }

    private var subscriptions: Set<AnyCancellable> = []

    init(siteID: Int64,
         siteURL: String = ServiceLocator.stores.sessionManager.defaultSite?.url ?? "",
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker(),
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.siteURL = siteURL
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.blazeEligibilityChecker = blazeEligibilityChecker
        self.state = .loading
        self.userDefaults = userDefaults
        observeSectionVisibility()
        configureResultsController()
    }

    @MainActor
    func reload() async {
        update(state: .loading)
        guard !userDefaults.hasDismissedBlazeSectionOnMyStore(for: siteID),
              await blazeEligibilityChecker.isSiteEligible() else {
            update(state: .empty)
            return
        }

        // Load Blaze campaigns
        await synchronizeBlazeCampaigns()

        if blazeCampaignResultsController.fetchedObjects.isEmpty {
            // Load published product as Blaze campaigns not available
            await synchronizeFirstPublishedProduct()
        }

        updateResults()
    }

    func checkIfIntroViewIsNeeded() {
        if blazeCampaignResultsController.numberOfObjects == 0 {
            shouldShowIntroView = true
        }
    }

    func didSelectCampaignList() {
        analytics.track(event: .Blaze.blazeCampaignListEntryPointSelected(source: .myStoreSection))
    }

    func didSelectCampaignDetails(_ campaign: BlazeCampaign) {
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
        userDefaults.setDismissedBlazeSectionOnMyStore(for: siteID)
        analytics.track(event: .Blaze.blazeViewDismissed(source: .myStoreSection))
    }
}

// MARK: - Blaze campaigns
private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func synchronizeBlazeCampaigns() async {
        await withCheckedContinuation({ continuation in
            stores.dispatch(BlazeAction.synchronizeCampaigns(siteID: siteID, pageNumber: Store.Default.firstPageNumber) { result in
                if case .failure(let error) = result {
                    DDLogError("⛔️ Dashboard — Error synchronizing Blaze campaigns: \(error)")
                }
                continuation.resume(returning: ())
            })
        })
    }
}


// MARK: - Products
private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func synchronizeFirstPublishedProduct() async {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.synchronizeProducts(siteID: siteID,
                                                              pageNumber: Store.Default.firstPageNumber,
                                                              pageSize: 1,
                                                              stockStatus: nil,
                                                              productStatus: .published,
                                                              productType: nil,
                                                              productCategory: nil,
                                                              sortOrder: .dateDescending,
                                                              shouldDeleteStoredProductsOnFirstPage: false,
                                                              onCompletion: { result in
                if case .failure(let error) = result {
                    DDLogError("⛔️ Dashboard — Error fetching first published product to show the Blaze campaign view: \(error)")
                }
                continuation.resume(returning: ())
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
            shouldShowInDashboard = true
        case .showCampaign, .showProduct:
            shouldRedactView = false
            shouldShowInDashboard = true
        case .empty:
            shouldRedactView = true
            shouldShowInDashboard = false
        }
        onStateChange?()
    }

    func updateResults() {
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
            self?.updateResults()
        }
        productResultsController.onDidResetContent = { [weak self] in
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

        userDefaults.publisher(for: \.hasDismissedBlazeSectionOnMyStore)
            .dropFirst() // ignores first event because data is already loaded initially.
            .map { [weak self] _ -> Bool in
                guard let self else {
                    return false
                }
                return self.userDefaults.hasDismissedBlazeSectionOnMyStore(for: self.siteID)
            }
            .removeDuplicates()
            .sink { [weak self] hasDismissed in
                guard let self else { return }
                guard !hasDismissed else {
                    self.update(state: .empty)
                    return
                }
                Task {
                    await self.reload()
                }
            }
            .store(in: &subscriptions)
    }
}

private extension BlazeCampaignDashboardViewModel {
    enum Constants {
        static let campaignDetailsURLFormat = "https://wordpress.com/advertising/campaigns/%d/%@?source=%@"
    }
}
