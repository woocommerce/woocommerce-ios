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

private extension BlazeCampaignDashboardViewModel {
    @MainActor
    func loadLatestBlazeCampaign() async throws -> BlazeCampaign? {
        // TODO: Replace with remote call
        try await Task.sleep(nanoseconds: 150_000_000)
        if Bool.random() {
            // swiftlint:disable:next line_length
            return .init(siteID: siteID, campaignID: 1, name: "Test", uiStatus: "finished", contentImageURL: "https://m.media-amazon.com/images/I/718JGhYeDXL.jpg", contentClickURL: "https://www.google.com/", totalImpressions: 1434, totalClicks: 211, totalBudget: 6563.2)
        } else {
            return nil
        }
    }

    @MainActor
    func loadFirstPublishedProduct() async throws -> Product? {
        // TODO: Replace with remote call
        try await Task.sleep(nanoseconds: 150_000_000)
        if Bool.random() {
            return Product.swiftUIPreviewSample()
        } else {
            return nil
        }
    }

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
