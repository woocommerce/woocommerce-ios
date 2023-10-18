import UIKit
import Yosemite
import Combine
import protocol Storage.StorageManagerType

/// View model for `BlazeCampaignDashboardView`.
final class BlazeCampaignDashboardViewModel: ObservableObject {
    /// UI state of the Blaze campaign view in dashboard.
    enum State {
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

    @Published private(set) var shouldShowInDashboard: Bool = true

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

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol

    /// Blaze campaign ResultsController.
    private lazy var blazeCampaignResultsController: ResultsController<StorageBlazeCampaign> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeCampaign.campaignID, ascending: false)
        let resultsController = ResultsController<StorageBlazeCampaign>(storageManager: storageManager,
                                                                        matching: predicate,
                                                                        sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    /// Product ResultsController.
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProduct.date, ascending: false)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

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

        configureResultsController()
    }

    @MainActor
    func reload() async {
        update(state: .loading)
        guard await blazeEligibilityChecker.isSiteEligible() else {
            update(state: .empty)
            return
        }

        // Load Blaze campaigns
        await synchronizeBlazeCampaigns()
        guard blazeCampaignResultsController.fetchedObjects.isEmpty else {
            return
        }

        // Load published product as Blaze campaigns not available
        await synchronizeFirstPublishedProduct()
        guard productResultsController.fetchedObjects.isEmpty else {
            return
        }

        // No Blaze campaign or published product available
        update(state: .empty)
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
        } else if let product = productResultsController.fetchedObjects.first(where: { $0.statusKey == ProductStatus.published.rawValue }) {
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
}
