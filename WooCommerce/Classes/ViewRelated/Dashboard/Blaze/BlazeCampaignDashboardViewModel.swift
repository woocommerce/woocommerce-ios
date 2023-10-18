import UIKit
import Yosemite
import Combine

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

    @Published private(set) var shouldShowInDashboard: Bool = false

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
    private let analytics: Analytics
    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker()) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.blazeEligibilityChecker = blazeEligibilityChecker
        self.state = .loading
    }

    @MainActor
    func reload() async {
        update(state: .loading)
        guard await blazeEligibilityChecker.isSiteEligible() else {
            update(state: .empty)
            return
        }

        if let campaign = try? await loadLatestBlazeCampaign() {
            update(state: .showCampaign(campaign: campaign))
        } else if let product = try? await loadFirstPublishedProduct() {
            update(state: .showProduct(product: product))
        } else {
            update(state: .empty)
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
            return ProductFactory().createNewProduct(type: .simple, isVirtual: false, siteID: siteID)
        } else {
            return nil
        }
    }

    @MainActor
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
}
