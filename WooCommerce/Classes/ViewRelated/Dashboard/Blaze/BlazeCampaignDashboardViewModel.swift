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

    private(set) var isRedacted: Bool = true

    var shouldShowShowAllCampaignsButton: Bool {
        if case .showCampaign(_) = state {
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
        let descriptor = NSSortDescriptor(key: "date", ascending: true)

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
    }

    func reload() async {
        await update(state: .loading)
        guard await blazeEligibilityChecker.isSiteEligible() else {
            await update(state: .empty)
            return
        }

        if let campaign = try? await loadLatestBlazeCampaign() {
            await update(state: .showCampaign(campaign: campaign))
        } else if let product = try? await loadFirstPublishedProduct() {
            await update(state: .showProduct(product: product))
        } else {
            await update(state: .empty)
        }
    }
}

// MARK: - Blaze campaigns
private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func loadLatestBlazeCampaign() async throws -> BlazeCampaign? {
        try await synchronizeBlazeCampaigns()
        try blazeCampaignResultsController.performFetch()
        return blazeCampaignResultsController.fetchedObjects.first
    }

    @MainActor
    func synchronizeBlazeCampaigns() async throws {
        try await withCheckedThrowingContinuation({ continuation in
            stores.dispatch(BlazeAction.synchronizeCampaigns(siteID: siteID, pageNumber: Store.Default.firstPageNumber) { result in
                switch result {
                case .success:
                    return continuation.resume(returning: ())
                case .failure(let error):
                    DDLogError("⛔️ Dashboard — Error synchronizing Blaze campaigns: \(error)")
                    return continuation.resume(throwing: error)
                }
            })
        })
    }
}


// MARK: - Products
private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func loadFirstPublishedProduct() async throws -> Product? {
        guard try await checkIfStoreHasPublishedProducts() else {
            return nil
        }
        try productResultsController.performFetch()
        return productResultsController.fetchedObjects.first(where: { $0.statusKey == ProductStatus.published.rawValue })
    }

    @MainActor
    private func checkIfStoreHasPublishedProducts() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.checkIfStoreHasProducts(siteID: siteID, status: .published, onCompletion: { result in
                switch result {
                case .success(let hasProducts):
                    continuation.resume(returning: hasProducts)
                case .failure(let error):
                    DDLogError("⛔️ Dashboard — Error fetching products to show the Blaze campaign view: \(error)")
                    continuation.resume(throwing: error)
                }
            }))
        }
    }
}

// MARK: - Helpers
private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func update(state: State) {
        self.state = state
        switch state {
        case .loading:
            isRedacted = true
            shouldShowInDashboard = true
        case .showCampaign, .showProduct:
            isRedacted = false
            shouldShowInDashboard = true
        case .empty:
            isRedacted = true
            shouldShowInDashboard = false
        }
        onStateChange?()
    }
}
